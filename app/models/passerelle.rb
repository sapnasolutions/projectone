class Passerelle < ActiveRecord::Base

  hobo_model # Don't put anything above this
  
  require "xmlsimple"

  fields do
    logiciel   	:string
    parametres 	:string
	tous_accueil :boolean
	#parametres 	:text
	# or create a model named parametres, bug with editor and text or hash
    timestamps
  end

  belongs_to :installation

  has_many :executions, :dependent => :destroy
  has_many :biens, :dependent => :destroy
  has_many :bien_photos
  
  #typed_serialize :parametres, Hash
  
  def save
	self.create_or_check_ftp
	super
  end
  
  def save!
	self.create_or_check_ftp
	super
  end
  
  def get_jobs
	Delayed::Job.all.select{ |j| 
			j.handler.include? "object: !ruby/module Importers"
		}.select{ |j|
			j.handler.include? "method_name: :import_passerelle"
		}.select{ |j|
			j.handler =~ /- !ruby\/ActiveRecord:Passerelle[^-]* id: ([0-9]*)[^-]*-/
			self.id == $1.to_i
		}
  end
  
  def get_execution_failed
	self.executions.select{ |e| e.statut != "ok" && e.statut != "nex" }
  end
  
  def get_jobs_failed
	self.get_jobs.select{ |j| j.attemps.to_i >= 3}
  end
  
  # va verifier et sinon créer l'accès FTP pour la passerelle (si celle ci à été configurée de cette manière)
  def create_or_check_ftp
	attrs = self.parametres.to_hashtribute
	# modifier le xml de filezilla pour ajouter un user
    unless attrs["dir"].to_s.empty? or attrs["loginFtp"].to_s.empty?
		# Ouverture du fichier de config de filezilla et mise en hashtable
		f = File.open("#{$filezilla_server_folder}/FileZilla Server.xml", "r+")
		data = f.read
		ftp_config = XmlSimple.xml_in(data)
		if ftp_config['Users']
			# search if allready exist one
			existing_user = ftp_config['Users'].first['User'].select{ |u| u['Name'] == attrs["loginFtp"]}.first
			if existing_user
				Logger.send("warn","Login #{attrs["loginFtp"]} allready exist on FTP : update account")
				all_dir = ftp_config['Users'].first['User'].map{ |u| u["Permissions"].first["Permission"].first["Dir"] }
				if (all_dir.include? (($base_ftp_repo+attrs["dir"]).slice(0..-2)).gsub(/\//,"\\\\")) && (existing_user["Permissions"].first["Permission"].first["Dir"] != (($base_ftp_repo+attrs["dir"]).slice(0..-2)).gsub(/\//,"\\\\"))
					Logger.send("warn","Dir #{attrs["dir"]} allready exist on an other FTP account can't create this new one")
					# raise ou pas une erreur ?
				else
					# search and delete the old one
					ftp_config['Users'].first['User'].delete existing_user
					# add a new one
					new_login = attrs["loginFtp"]
					if attrs["pass"].to_s.empty?
						new_pass = ""
					else
						new_pass = Digest::MD5.hexdigest attrs["pass"].to_s
					end
					new_dir = (($base_ftp_repo+attrs["dir"]).slice(0..-2)).gsub(/\//,"\\\\")
					new_user = {"Name"=> new_login, "Option"=>[{"Name"=>"Pass", "content" => new_pass}, {"Name"=>"Group"}, {"Name"=>"Bypass server userlimit", "content"=>"0"}, {"Name"=>"User Limit", "content"=>"0"}, {"Name"=>"IP Limit", "content"=>"0"}, {"Name"=>"Enabled", "content"=>"1"}, {"Name"=>"Comments"}, {"Name"=>"ForceSsl", "content"=>"0"}], "IpFilter"=>[{"Disallowed"=>[{}], "Allowed"=>[{}]}], "Permissions"=>[{"Permission"=>[{"Dir"=> new_dir, "Option"=>[{"Name"=>"FileRead", "content"=>"1"}, {"Name"=>"FileWrite", "content"=>"1"}, {"Name"=>"FileDelete", "content"=>"1"}, {"Name"=>"FileAppend", "content"=>"1"}, {"Name"=>"DirCreate", "content"=>"1"}, {"Name"=>"DirDelete", "content"=>"1"}, {"Name"=>"DirList", "content"=>"1"}, {"Name"=>"DirSubdirs", "content"=>"1"}, {"Name"=>"IsHome", "content"=>"1"}, {"Name"=>"AutoCreate", "content"=>"1"}]}]}], "SpeedLimits"=>[{"DlType"=>"0", "DlLimit"=>"10", "ServerDlLimitBypass"=>"0", "UlType"=>"0", "UlLimit"=>"10", "ServerUlLimitBypass"=>"0", "Download"=>[{}], "Upload"=>[{}]}]}
					ftp_config['Users'].first['User'] << new_user
				end
			else
				Logger.send("warn","Login #{attrs["loginFtp"]} doesn't exist : create account")
				all_dir = ftp_config['Users'].first['User'].map{ |u| u["Permissions"].first["Permission"].first["Dir"] }
				if all_dir.include? (($base_ftp_repo+attrs["dir"]).slice(0..-2)).gsub(/\//,"\\\\")
					Logger.send("warn","Dir #{attrs["dir"]} allready exist on an other FTP account can't create this new one")
					# raise ou pas une erreur ?
				else
					new_login = attrs["loginFtp"]
					if attrs["pass"].to_s.empty?
						new_pass = ""
					else
						new_pass = Digest::MD5.hexdigest attrs["pass"].to_s
					end
					new_dir = (($base_ftp_repo+attrs["dir"]).slice(0..-2)).gsub(/\//,"\\\\")
					new_user = {"Name"=> new_login, "Option"=>[{"Name"=>"Pass", "content" => new_pass}, {"Name"=>"Group"}, {"Name"=>"Bypass server userlimit", "content"=>"0"}, {"Name"=>"User Limit", "content"=>"0"}, {"Name"=>"IP Limit", "content"=>"0"}, {"Name"=>"Enabled", "content"=>"1"}, {"Name"=>"Comments"}, {"Name"=>"ForceSsl", "content"=>"0"}], "IpFilter"=>[{"Disallowed"=>[{}], "Allowed"=>[{}]}], "Permissions"=>[{"Permission"=>[{"Dir"=> new_dir, "Option"=>[{"Name"=>"FileRead", "content"=>"1"}, {"Name"=>"FileWrite", "content"=>"1"}, {"Name"=>"FileDelete", "content"=>"1"}, {"Name"=>"FileAppend", "content"=>"1"}, {"Name"=>"DirCreate", "content"=>"1"}, {"Name"=>"DirDelete", "content"=>"1"}, {"Name"=>"DirList", "content"=>"1"}, {"Name"=>"DirSubdirs", "content"=>"1"}, {"Name"=>"IsHome", "content"=>"1"}, {"Name"=>"AutoCreate", "content"=>"1"}]}]}], "SpeedLimits"=>[{"DlType"=>"0", "DlLimit"=>"10", "ServerDlLimitBypass"=>"0", "UlType"=>"0", "UlLimit"=>"10", "ServerUlLimitBypass"=>"0", "Download"=>[{}], "Upload"=>[{}]}]}
					ftp_config['Users'].first['User'] << new_user
					Logger.send("warn","FTP account succeffully created")
				end
			end
			new_data = XmlSimple.xml_out(ftp_config, 'rootname' => 'FileZillaServer')
			f.pos = 0                     # back to start
			f.print new_data                 # write out modified lines
			f.truncate(f.pos)
		else
			Logger.send("warn","Need to create 1 FTP account")
		end
		f.close
		# Command pour mettre à jour FTPfile zilla
		system ("\"#{$filezilla_server_folder}/FileZilla server.exe\" -reload-config")
		Logger.send("warn","FileZilla accounts settings file updated")
	else
		Logger.send("warn","Passerelle could not create a FTP account")
	end
  end
  
  def name
	return self.logiciel
  end
  
  def execute
	Importers.delay(:priority => 0).import_passerelle(self,Time.now)
	Logger.send("warn","Passerelle is executed")
  end
  
  def force_execution
	Logger.send("warn","Passerelle is forced to be executed")
	self.executions.last.destroy
	self.execute
  end
  
  def execution_from_scratch
	Logger.send("warn","Passerelle is executed from scratch")
	self.executions.each{ |e| e.destroy }
	self.biens.each{ |e| e.destroy }
	self.execute
  end
  
  def update_exe

  end
  
  # --- Permissions --- #

  def execute_permitted?
	acting_user.administrator?
  end
  
  def update_exe_permitted?
	acting_user.administrator?
  end
  
  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end
