class Importers::Totalimmo < Importers::FromFiles
  
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  #waiting parameters : code_agence
  TOTAL_FTP_FOLDER = "totalimmo/"
  
  def scan_files
    Logger.send("warn","[FILE] Start scan files")
	@result[:description] << "[FILE] Start scan files"
    
	unless File.exists? $base_ftp_repo+TOTAL_FTP_FOLDER
	  Logger.send("warn","[FILE] Directory #{TOTAL_FTP_FOLDER} does not exist.")
	  @result[:description] << "[FILE] Directory #{TOTAL_FTP_FOLDER} does not exist."
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
        ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).first.nil? && filename =~ /#{@parameters["code_agence"]}(location|vente)\.zip/
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
	Logger.send("warn","[Totalimmo] Starting execution import")
	@result[:description] << "[Totalimmo] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

	dl_and_update_medias z

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
	  Logger.send("warn","[Totalimmo] XML name : "+entry.name)
      data = z.read(entry)
	  
	  data = data.gsub(/ < /,"&lsaquo;")
	  data = data.gsub(/ > /,"&rsaquo;")
	  if entry.name.downcase =~ /location/
		@transaction_type = BienTransaction.where(:nom => "Location").first
	  elsif entry.name.downcase =~ /vente/
		@transaction_type = BienTransaction.where(:nom => "Vente").first
	  else
		raise "Erreur sur le nom du fichier #{entry.name.downcase}"
	  end
      tree = Hash.from_xml(data)
	  
	  import_hash(tree)
    end
    
    z.close

    maj_biens @transaction_type
    
	Logger.send("warn","[Totalimmo] Finished execution import")
	@result[:description] << "[Totalimmo] Finished execution import"
    return @result
  end
  
  # Import a hash in Totalimmo tree format.
  
  def import_hash hashtree
	Logger.send("warn","[Totalimmo] Start XML(hash) import")
	@result[:description] << "[Totalimmo] Start XML(hash) import"

    # Create and list new goods
    hashtree["liste"]["bien"].each { |b|
      import_bien b
    }
	
	Logger.send("warn","[Totalimmo] End XML import")
	@result[:description] << "[Totalimmo] End XML import"
    return true
  end
  
  CODE_MATCHING = {"1" =>  "Appartement", "2" => "Maison", "3" => "Stationnement", "4" => "Locaux commerciaux", "5" => "Appartement meubl\é", "6" => "Chambre", "7" => "Bureau"}
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b["BIEN_CODE_POSTAL"]
	loc.ville = b["BIEN_VILLE"]

	ref = b["BIEN_REFERENCE"]
	
	if @transaction_type.nom == "Vente"
		cat = b["BIEN_TYPE"].to_s
		price = b["BIEN_PRIX"]
	else
		cat_code = b["BIEN_TYPE"].to_s
		cat = CODE_MATCHING[cat_code]
		price = b["BIEN_LOYER"]
	end
	
	cat = BienType.where(:nom => cat.to_s.titlecase).first
	if cat.nil?
		cat = BienType.new(:nom => cat.to_s.titlecase)
		cat.save!
	end
    
	nb = Bien.where(:reference => ref).first
    nb = Bien.new if nb.nil?
	
	desc = b["BIEN_DESCRIPTION"]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = @transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["BIEN_NB_PIECE"]
    nb.nb_chambre = b["BIEN_NB_CHAMBRE"]
    nb.surface = b["BIEN_SURFACE_TOTALE"]
    nb.surface_terrain = b["BIEN_SURFACE_TERRAIN"]
    nb.titre = b["BIEN_LIBELLE"]
    nb.prix = price
    nb.description = desc
	
	nb.statut = 'new'
    nb.save!
	
	nb.valeur_dpe = b["BIEN_CONSO_ENERGETIQUE"]
	nb.valeur_ges = b["BIEN_EMISSION_GES"]
		
	# If new images : Drop old images, add current images
    if b["photo"]
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b["photo"]
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
	  counter = 0
      pl.map { |p| import_local_media("#{p.to_s}.jpg",(counter+=1),nb,"#{p.to_s}.jpg") }
    end
	
    nb.save!

    return
	end
	
  end