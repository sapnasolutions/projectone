class Importers::Immovision < Importers::FromFiles
  
  def initialize passerelle
    super passerelle, %w(application/zip)
  end

  #waiting parameters : code_agence
  IMMOVISION_FTP_FOLDER = "immovision/"
  
  #Import only file who's named 'c21.zip'
  def scan_files
    Logger.send("warn","[FILE] Start scan files")
	@result[:description] << "[FILE] Start scan files"
    
	unless File.exists? $base_ftp_repo+IMMOVISION_FTP_FOLDER
	  Logger.send("warn","[FILE] Directory #{IMMOVISION_FTP_FOLDER} does not exist.")
	  @result[:description] << "[FILE] Directory #{IMMOVISION_FTP_FOLDER} does not exist."
      return
    end
	
	# obtain a list of recent zips, sorted by modification time,
    # that can be opened as zipfiles, and save them
    pattern = File.join($base_ftp_repo+IMMOVISION_FTP_FOLDER, '*')
    Dir[pattern].sort { |a,b|
		File.mtime(a) <=> File.mtime(b)
    }.select{ |path|
		tmp_file = File.new(path,"r+b")
		filename = File.basename path
        ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty?
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
	Logger.send("warn","[Immovision] Starting execution import")
	@result[:description] << "[Immovision] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

	update_remote_medias

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
	  
	  data = z.read(entry)
      tree = Hash.from_xml(data)
      return if tree.nil? || tree["ANNONCES"].nil? || tree["ANNONCES"]["ANNONCE"].nil?
      import_hash(tree)
    end
    
    z.close

    maj_biens
    
	Logger.send("warn","[Immovision] Finished execution import")
	@result[:description] << "[Immovision] Finished execution import"
    return @result
  end

  # Import a hash in Trans21 tree format.
  def import_hash hashtree
	Logger.send("warn","[Immovision] Start XML(hash) import")
	@result[:description] << "[Immovision] Start XML(hash) import"

    goods_list = hashtree["ANNONCES"]["ANNONCE"]
    goods_list = [goods_list] unless goods_list.kind_of? Array
	
	# Actually not used, un-comment and re-adapt if agencies management
	# agencies.each { |a|
      # import_agency a if agency_belongs_to_client? a
    # }
	
	# Create and list new goods
	  goods_list.each { |b|
		import_bien b
	  }

	Logger.send("warn","[Immovision] End XML import")
	@result[:description] << "[Immovision] End XML import"
    return true
  end

  # def import_agency a
    ##Agency and its location
    # source_key = "trans21-" + a["code_agence"]
    # agency = Immo::Agency.get source_key
    # agency.name    = a["nom"].to_s.titlecase
    # agency.phone   = a["telephone"]
    # agency.email   = a["email"]
    ##agency.website = ???

    # address = {}
    # address[:address]  = a["adresse"]
    # address[:city]     = a["ville"]
    # address[:zipcode]  = a["code_postal"]
    # address[:country]  = "France"
    # agency.location    = Immo::Location.get address

    # agency.save!
  # end

  def find_cat text
	cats = {"0" => "Fonds de commerces", "1" => "Appartements", "2" => "Maisons Villas", "3" => "Terrains", "4" => "Entreprises", "5" => "Droit au bail", "6" => "Locaux commerciaux", "7" => "Murs commerciaux", "8" => "Terrains industriels", "9" => "Gerances fond commerce", "10" => "Parkings", "11" => "Garages", "12" => "Exploitations agricoles"}
	return "Autre" if cats[text.to_s].nil?
	return cats[text.to_s]
  end

  # Create a new good, and return the ActiveRecord
  def import_bien b
  
	return if b["AGENCE_REF"].nil? or b["AGENCE_REF"].empty? or b["AGENCE_REF"].to_s != @parameters["code_agence"]
	# Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.ville = b["VILLE"].up_first
	loc.code_postal = b["CP"]

	ref = b["REFERENCE"]
	
	cat = BienType.find_or_create find_cat(b['TYPE']).up_first
	
	# Determine if the good is a sell or a rent
    if b['TRANSACTION'].to_i == 1
      transaction_type = BienTransaction.where(:nom => 'Vente').first
    elsif b['TRANSACTION'].to_i == 2
	  transaction_type = BienTransaction.where(:nom => 'Location').first
    else
		Logger.send("warn","Type vente | location null pour le bien ref : "+b["REFERENCE"])
		@result[:description] << "Type vente | location null pour le bien ref : "+b["REFERENCE"]
        return false
    end
	price = b["PRIX"].to_i
	
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?
	
	desc = b["DESCRIPTION_FR"]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

	nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["NB_PIECE"]
    nb.nb_chambre = b["NB_CHAMBRE"]
    nb.surface = b["SURFACE"]
    nb.surface_terrain = b["SURFACE_TERRAIN"]
    nb.titre = b["TITRE_FR"]
    nb.prix = price
    nb.description = desc
	
	nb.valeur_dpe = b["ETIQUETTE_ENERGIE"]
	nb.classe_dpe = b["ETIQUETTE_ENERGIE"]	
	nb.valeur_ges = b["ETIQUETTE_CLIMAT"]
	nb.class_ges = b["ETIQUETTE_CLIMAT"]
		
	nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b["LISTE_PHOTOS"] && b["LISTE_PHOTOS"]["PHOTO_1"]
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
	 pl = []
	 20.times{ |i|
		pl.push b["LISTE_PHOTOS"]["PHOTO_#{i+1}"] unless b["LISTE_PHOTOS"]["PHOTO_#{i+1}"].nil? or b["LISTE_PHOTOS"]["PHOTO_#{i+1}"].empty? 
	 }
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
	  counter = 0
      pl.map { |p| import_remote_media(p.to_s,(counter+=1),nb) }
    end
	
    nb.save!

    return
  end
  
  
end