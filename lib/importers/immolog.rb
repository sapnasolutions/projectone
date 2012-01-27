class Importers::Immolog < Importers::FromFiles
  require 'csv'
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  #waiting parameters : code_agence
  TOTAL_FTP_FOLDER = "immolog/"
  
  def scan_files
    Logger.send("warn","[IMMOLOG] Start scan files")
	@result[:description] << "[IMMOLOG] Start scan files"
    
	unless File.exists? $base_ftp_repo+TOTAL_FTP_FOLDER
	  Logger.send("warn","[IMMOLOG] Directory #{TOTAL_FTP_FOLDER} does not exist.")
	  @result[:description] << "[IMMOLOG] Directory #{TOTAL_FTP_FOLDER} does not exist."
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
	Logger.send("warn","[IMMOLOG] Starting execution import")
	@result[:description] << "[IMMOLOG] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

	dl_and_update_medias z

    z.each do |entry|
      next unless entry.name.downcase =~ /.csv$/
      data = z.read(entry)
	  
	  data = Iconv.conv('utf-8','cp1252',data.to_s)
	  data.gsub!(/"/,"")
      
	  data.to_s.gsub!(/,/,"{virgule}")
	  data.to_s.gsub!(/;/,",")
    
      csv_parsed = CSV.parse(data)
		csv_parsed.each{ |line|
			line.each{ |info| info.to_s.gsub!(/{virgule}/,",")
			}
	  }
	  
	  import_hash(csv_parsed)
    end
    
    z.close

    maj_biens @transaction_type
    
	Logger.send("warn","[IMMOLOG] Finished execution import")
	@result[:description] << "[IMMOLOG] Finished execution import"
    return @result
  end
  
  # Import a hash in Totalimmo tree format.
  
  def import_hash hashtree
	Logger.send("warn","[IMMOLOG] Start CSV(hash) import")
	@result[:description] << "[IMMOLOG] Start CSV(hash) import"

    # Create and list new goods
    hashtree.each { |b|
      import_bien b
    }
	
	Logger.send("warn","[IMMOLOG] End CSV import")
	@result[:description] << "[IMMOLOG] End CSV import"
    return true
  end
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b[4]
	loc.ville = b[5]

	ref = b[0]
	
	cat = nil
	price = b[6]
	
	if b[1] == "Vente"
		ttype = BienTransaction.where(:nom => "Vente").first
	else
		ttype = BienTransaction.where(:nom => "Location").first
	end
    
	nb = Bien.where(:reference => ref).first
    nb = Bien.new if nb.nil?
	
	desc = b[10]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = ttype
    nb.bien_emplacement = loc
    nb.nb_piece = b[7]
    nb.nb_chambre = b[8]
    nb.surface = b[9]
    #nb.surface_terrain = b["BIEN_SURFACE_TERRAIN"]
    nb.titre = b[3].to_s
    nb.prix = price
    nb.description = desc
	
	nb.statut = 'new'
    nb.save!
	
	#nb.valeur_dpe = b["BIEN_CONSO_ENERGETIQUE"]
	#nb.valeur_ges = b["BIEN_EMISSION_GES"]
		
	# If new images : Drop old images, add current images
	photo = []
	10.times{ |i| photo.push b[i+11].to_s }
	photo.reject!{ |p| p.nil? || p.empty?}
    if photo && !photo.empty?
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = photo
      
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