class Importers::Immoselect < Importers::FromFiles
  
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  #waiting parameters : code_agence
  TOTAL_FTP_FOLDER = "immoselect/"
  
  def scan_files
    Logger.send("warn","[Immoselect] Start scan files")
	@result[:description] << "[Immoselect] Start scan files"
    
	unless File.exists? $base_ftp_repo+TOTAL_FTP_FOLDER
	  Logger.send("warn","[Immoselect] Directory #{TOTAL_FTP_FOLDER} does not exist.")
	  @result[:description] << "[Immoselect] Directory #{TOTAL_FTP_FOLDER} does not exist."
      return
    end
	
	# obtain a list of recent zips, sorted by modification time,
    # that can be opened as zipfiles, and save them
    pattern = File.join($base_ftp_repo+TOTAL_FTP_FOLDER, '*')
    Dir[pattern].sort { |a,b|
		File.mtime(a) <=> File.mtime(b)
    }.select{ |path|
		tmp_file = File.new(path,"r+b")
		filename = File.basename path
        ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty? && filename =~ /#{@parameters["code_agence"]}\.zip/
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
	Logger.send("warn","[Immoselect] Starting execution import")
	@result[:description] << "[Immoselect] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

	dl_and_update_medias z

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
      data = z.read(entry)
      tree = Hash.from_xml(data)
	  import_hash(tree)
    end
    
    z.close

    maj_biens @transaction_type
    
	Logger.send("warn","[Immoselect] Finished execution import")
	@result[:description] << "[Immoselect] Finished execution import"
    return @result
  end
  
  # Import a hash in Immoselect tree format.
  
  def import_hash hashtree
	Logger.send("warn","[Immoselect] Start XML(hash) import")
	@result[:description] << "[Immoselect] Start XML(hash) import"

    # Create and list new goods
    hashtree["biens"]["bien"].each { |b|
      import_bien b
    }
	
	Logger.send("warn","[Immoselect] End XML import")
	@result[:description] << "[Immoselect] End XML import"
    return true
  end
  
  CODE_MATCHING = {"1" =>  "Appartement", "2" => "Maison", "3" => "Stationnement", "4" => "Locaux commerciaux", "5" => "Appartement meubl\é", "6" => "Chambre", "7" => "Bureau"}
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = b["nom_pays"]
	loc.code_postal = b["code_postal"]
	loc.ville = b["ville"]

	if b["reference"].kind_of? Array
		ref = b["reference"].first
	else
		ref = b["reference"]
	end
	return if ref.nil? or ref.empty?
	
	transaction_type = BienTransaction.where(:nom => b['type_transaction'].up_first).first
	return if transaction_type.nil?
	
	cat = BienType.find_or_create b["type_bien"].up_first
    
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?
	
	desc = b["description_internet"]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["nb_piece"]
    nb.surface = b["surface_habitable"]
    nb.titre = b["type_bien"].up_first
    nb.prix = b["prix"]
    nb.description = desc
	
	nb.statut = 'new'
    nb.save!
	
	nb.valeur_dpe = b["valeur_energie"]
	nb.valeur_ges = b["valeur_ges"]
	nb.classe_dpe = b['bilan_energie']
	nb.class_ges = b['bilan_ges']
		
	# If new images : Drop old images, add current images
    if b["images"]["image"]
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b["images"]["image"]
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
	  counter = 0
      pl.map { |p| import_local_media(p.to_s,(counter+=1),nb,p.to_s) }
    end
	
    nb.save!

    return
	end
	
  end