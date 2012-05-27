class Importers::Laresidence < Importers::FromFiles
  
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  #waiting parameters : code_agence
  LARESIDENCE_FTP_FOLDER = "laresidence/"
  
  def scan_files
    Logger.send("warn","[Laresidence] Start scan files")
	@result[:description] << "[Laresidence] Start scan files"
    
	unless File.exists? $base_ftp_repo+LARESIDENCE_FTP_FOLDER
	  Logger.send("warn","[Laresidence] Directory #{LARESIDENCE_FTP_FOLDER} does not exist.")
	  @result[:description] << "[Laresidence] Directory #{LARESIDENCE_FTP_FOLDER} does not exist."
      return
    end
	
	# obtain a list of recent zips, sorted by modification time,
    # that can be opened as zipfiles, and save them
    pattern = File.join($base_ftp_repo+LARESIDENCE_FTP_FOLDER, '*')
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
	Logger.send("warn","[Laresidence] Starting execution import")
	@result[:description] << "[Laresidence] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

	dl_and_update_medias z

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
      data = z.read(entry)
      tree = XmlSimple.xml_in(data)
      import_hash(tree)
    end
    
    z.close

    maj_biens @transaction_type
    
	Logger.send("warn","[Laresidence] Finished execution import")
	@result[:description] << "[Laresidence] Finished execution import"
    return @result
  end
  
  # Import a hash in Enova tree format.
  
  def import_hash hashtree
	Logger.send("warn","[Laresidence] Start XML(hash) import")
	@result[:description] << "[Laresidence] Start XML(hash) import"

    Logger.send("warn","[Laresidence] #{hashtree["bien"].size} goods in hash")
	@result[:description] << "[Laresidence] #{hashtree["bien"].size} goods in hash"
    # Create and list new goods
    hashtree["bien"].each { |b|
      import_bien b
    }
	
	Logger.send("warn","[Laresidence] End XML import")
	@result[:description] << "[Laresidence] End XML import"
    return true
  end
  
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = b["nom_pays"].first if b["nom_pays"]
	loc.code_postal = b["code_postal"].first if b["code_postal"]
	loc.ville = b["ville"].first if b["ville"]

        ref = b["num_mandat"].first if b["num_mandat"]
	return if ref.nil? or ref.empty?
	
	return if b['type_transaction'].nil?
	transaction_type = BienTransaction.where(:nom => b['type_transaction'].first.up_first).first
	return if transaction_type.nil?
	
	cat = BienType.find_or_create b["type_bien"].first.up_first if b["type_bien"]
    
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?
	
	desc = b["description"].first if b["description"]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["nb_piece"].first if b["nb_piece"]
    nb.nb_chambre = b["nb_chambre"].first if b["nb_chambre"]
    nb.surface = b["surface_habitable"].first if b["surface_habitable"]
    nb.surface_terrain = b["surface_terrain"].first if b["surface_terrain"]
    nb.titre = b["type_bien"].first.up_first if b["type_bien"]
    nb.prix = b["prix"].first.to_i if b["prix"]
    
    nb.description = desc
	
    nb.statut = 'new'
    nb.save!

    if b["complement"]
	nb.valeur_dpe = b["complement"].select{ |a| a["type"] == "valeur_energie" }.map{ |a| a["content"]}.first.to_i
	nb.valeur_ges = b["complement"].select{ |a| a["type"] == "valeur_ges" }.map{ |a| a["content"]}.first.to_i
	nb.classe_dpe = b["complement"].select{ |a| a["type"] == "bilan_energie" }.map{ |a| a["content"]}.first.to_s
	nb.class_ges = b["complement"].select{ |a| a["type"] == "bilan_ges" }.map{ |a| a["content"]}.first.to_s
    end		
	# If new images : Drop old images, add current images
    if b["images"].first["image"]
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b["images"].first["image"]
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
	  counter = 0
      pl.map { |p| import_local_media(p["content"].to_s,(counter+=1),nb,p["content"].to_s) }
    end
	
    nb.save!

    return
	end
	
  end