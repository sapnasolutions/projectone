# encoding: utf-8
module Importers
  ModuleMapping = {
    'pericles' => Importers::Pericles,
	'adaptimmo' => Importers::Adaptimmo,
	'ubiflow' => Importers::Ubiflow,
    'goventis' => Importers::Goventis,
	'immolog' => Importers::Immolog,
	'ac3' => Importers::Ac3,
	'gemea' => Importers::Gemea,
	'aftim' => Importers::Aftim,
	'ics' => Importers::Ics,
	'nexto' => Importers::Nexto,
    'immoselect' => Importers::Immoselect,
    'pagesimmows' => Importers::PagesimmoWs,
    'pagesimmoftp' => Importers::PagesimmoFtp,
    'enova' => Importers::Enova,
    'rom' => Importers::Rom,
    'agenceplus' => Importers::AgencePlus,
    'laresidence' => Importers::Laresidence,
    'aptalis' => Importers::Aptalis,
    'totalimmo' => Importers::Totalimmo,
    'trans21' => Importers::Trans21,
    'cosmosoft' => Importers::Cosmosoft,
    'immovision' => Importers::Immovision,
  }
  # New family of importer : the group importer
  GroupImporter = ['chronotech']

  # Run `import` on all known clients who have an app, an importer and importer's is not a group importer
  def self.run (recent = 1.hours.ago)
	# @rapport_import = ""
	# @nb_fail = 0
    Passerelle.all.each do |passerelle|
      #self.send_later(:import,client)
	  self.delay(:priority => 10).import_passerelle(passerelle, recent)
    end
	# @rapport_import << "Fin import #{Passerelle.all} de passerelles : #{@nb_fail} imports en echec"
	
  end
  
  # Import unknown object (can be client, installation, passerelle, nil ...). FIXME (do the import methods in the model)
  def self.import (object, recent = 1.hours.ago)
	case object.class.name
	when "Client" then
		self.import_client(object, recent)
	when "String" then
		Client.first(:conditions => {:name => object})
		#raise "Unknown client login : #{object}"
		self.import_client(object, recent)
	when "Installation" then
		self.import_installation(object, recent)
	when "Passerelle" then
		self.import_passerelle(object, recent)
	else
		raise "Unknown class object to import : #{object.class.name}"
	end
  end
  
  def self.import_client(client, recent = 1.hours.ago)
	Logger.send("warn","[Client] Start import #{client.name} : #{client.installations.size.to_s} installation")
    client.installations.each{|i|
		self.import_installation(i,recent)
	}
	Logger.send("warn","[Client] End import #{client.name}")
  end
  
  def self.import_installation(installation, recent = 1.hours.ago)
	Logger.send("warn","[Installation] Start import #{installation.code_acces_distant} : #{installation.passerelles.size.to_s} passerelle")
	installation.passerelles.each{|p|
		self.import_passerelle(p,recent)
	}
	Logger.send("warn","[Installation] End import #{installation.code_acces_distant}")
  end
  
  def self.import_passerelle(passerelle, recent = 1.hours.ago)
	@rapport_import = "" if @rapport_import.nil?
	@rapport_import << "-> #{passerelle.installation.client.name} | #{passerelle.installation.code_acces_distant} | #{passerelle.logiciel}/#{passerelle.parametres} : "
	
	Logger.send("warn","[Passerelle] Start import #{passerelle.logiciel}/#{passerelle.parametres}")
	# check time
    unless passerelle.updated_at.nil? or passerelle.updated_at < recent
		Logger.send("warn","[Passerelle] Skipping passerelle, updated too recently (#{passerelle.updated_at.to_s}) ")
		return
    end
	# check importer :FIXME (proposer la liste des passerelles ‡ la crÈation (pour Èviter les erreurs)
	mod = Importers::ModuleMapping[passerelle.logiciel]
    if mod.nil?
		Logger.send("warn","[Passerelle] Logiciel : (#{passerelle.logiciel.to_s}) non connu ")
		return
    end
	# Import the passerelle
	begin
		res = mod.new(passerelle).import
		if res["updated"]
			@rapport_import << "Updated<br\>"
		else
			@rapport_import << "Not updated<br\>"
		end
		Logger.send("warn","[Passerelle] Import completed")
    rescue Exception => e
		@rapport_import << "Fail<\br>"
		@rapport_import << "Error message => : #{e.message}<\br>"
		@rapport_import << "Error backtrace => #{e.backtrace}<\br>"
		Logger.send("warn","[Passerelle] Import FAIL !")
		Logger.send("warn","[Passerelle] Rapport : #{@rapport_import}")
    end
  end
  
  
  
  
  
    # Reset unknown object (can be client, installation, passerelle, nil ...). FIXME (do the reset methods in the model)
  def self.reset(object, nb_file_reseted = nil)
	case object.class.name
	when "Client" then
		self.reset_client(object, nb_file_reseted)
	when "String" then
		Client.first(:conditions => {:name => object})
		raise "Unknown client login : #{object}"
		self.reset_client(object, nb_file_reseted)
	when "Installation" then
		self.reset_installation(object, nb_file_reseted)
	when "Passerelle" then
		self.reset_passerelle(object, nb_file_reseted)
	else
		raise "Unknown class object to reset : #{object.class.name}"
	end
  end
  
  def self.reset_client(client, nb_file_reseted = nil)
	Logger.send("warn","[Client] Start reset #{client.name} : #{client.installations.size.to_s} installation")
    client.installations.each{|i|
		self.reset_installation(i,nb_file_reseted)
	}
	Logger.send("warn","[Client] End reset #{client.name}")
  end
  
  def self.reset_installation(installation, nb_file_reseted = nil)
	Logger.send("warn","[Installation] Start reset #{installation.code_acces_distant} : #{installation.passerelles.size.to_s} passerelle")
	installation.passerelles.each{|p|
		self.reset_passerelle(p,nb_file_reseted)
	}
	Logger.send("warn","[Installation] End reset #{installation.code_acces_distant}")
  end
  
  def self.reset_passerelle(passerelle, nb_file_reseted = nil)
	Logger.send("warn","[Passerelle] Start reset #{passerelle.logiciel}")
	result = Execution.where(:passerelle_id => passerelle.id).order("created_at desc")
	total = result.size
	reseted = result.size
	unless nb_file_reseted.nil?
		result = result.limit(nb_file_reseted)
		reseted = result.size
	end
	result.each{ |execution|
		execution.statut = "nex"
		execution.save!
	}
	Logger.send("warn","[Passerelle] End reset")
  end
  
end