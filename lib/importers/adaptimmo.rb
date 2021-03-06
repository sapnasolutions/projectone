class Importers::Adaptimmo < Importers::FromFiles
  
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(plain/text)
  end
  
  #waiting parameters : code_agence
  ADAPTIMMO_FTP_FOLDER = "adaptimmo/"
  
  def scan_files
    Logger.send("warn","[Adaptimmo] Start scan files")
	@result[:description] << "[Adaptimmo] Start scan files"
    
	unless File.exists? $base_ftp_repo+ADAPTIMMO_FTP_FOLDER
	  Logger.send("warn","[Adaptimmo] Directory #{ADAPTIMMO_FTP_FOLDER} does not exist.")
	  @result[:description] << "[Adaptimmo] Directory #{ADAPTIMMO_FTP_FOLDER} does not exist."
      return
    end
	
	# obtain a list of recent zips, sorted by modification time,
    # that can be opened as zipfiles, and save them
    pattern = File.join($base_ftp_repo+ADAPTIMMO_FTP_FOLDER, '*')
    Dir[pattern].sort { |a,b|
		File.mtime(a) <=> File.mtime(b)
    }.select{ |path|
		tmp_file = File.new(path,"r+b")
		filename = File.basename path
        ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty? && filename =~ /#{@parameters["code_agence"]}\.xml/
	}.each { |path|
	# self.from_file(filename,file,execution)
		name = path
		tmp_file = File.new(path,"r+b")
		e = Execution.new
		e.passerelle = @passerelle
		e.statut = "nex"
		e.save!
		f = ExecutionSourceFile.from_file(name,tmp_file,e)
		e.execution_source_file = f
		e.save!
    }
  end
  
  def import_exe execution
	Logger.send("warn","[Adaptimmo] Starting execution import")
	@result[:description] << "[Adaptimmo] Starting execution import"

	f = File.open(execution.execution_source_file.file.path)
    data = f.read
    hash = Hash.from_xml(data)
	import_hash(hash)
	
	f.close

    maj_biens @transaction_type
    
	Logger.send("warn","[Adaptimmo] Finished execution import")
	@result[:description] << "[Adaptimmo] Finished execution import"
    return @result
  end
  
  # Import a hash in Immoselect tree format.
  
  def import_hash hashtree
	Logger.send("warn","[Adaptimmo] Start XML(hash) import")
	@result[:description] << "[Adaptimmo] Start XML(hash) import"

    # Create and list new goods
    hashtree["adapt_xml"]["annonce"].each { |b|
      import_bien b
    }
	
	Logger.send("warn","[Adaptimmo] End XML import")
	@result[:description] << "[Adaptimmo] End XML import"
    return true
  end
  
  CODE_MATCHING = {"1" =>  "Appartement", "2" => "Maison", "3" => "Stationnement", "4" => "Locaux commerciaux", "5" => "Appartement meubl\�", "6" => "Chambre", "7" => "Bureau"}
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = b["pays"]
	loc.code_postal = b["code_postal"]
	loc.ville = b["ville"]

	ref = b["reference"]
	return if ref.nil? or ref.empty?
	
	transaction_type = BienTransaction.where(:nom => b['operation'].up_first).first
	return if transaction_type.nil?
	
	cat = BienType.find_or_create b["famille"].up_first
    
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?
	
	desc = b["texte_fr"]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["piece"]
    nb.surface = b["surf_hab"]
	#surf_terrain
	#nb_chambre
	#titre_fr
    nb.titre = b["titre_fr"]
    nb.prix = b["prix"]
    nb.description = desc
	
	nb.statut = 'new'
    nb.save!
	
	nb.valeur_dpe = b["dpe_consom_energ"]
	nb.valeur_ges = b["dpe_emissions_ges"]
	nb.classe_dpe = b['dpe_lettre_consom_energ']
	nb.class_ges = b['dpe_lettre_emissions_ges']
		
	# If new images : Drop old images, add current images
    if b["liste_photos"]["photo"]
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b["liste_photos"]["photo"]
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
	  counter = 0
      pl.map { |p| import_remote_media(p.to_s,(counter+=1),nb) }
    end
	
    nb.save!

    return
	end
	
  end