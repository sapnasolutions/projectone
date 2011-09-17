class Importers::Aptalis < Importers::FromUrls
  # PARTNER = 'HILABS'
  # CODE = '678jksq5'
  
  PARTNER = 'VIRTUALTOUCH'
  CODE = 'gfdsg654df3qfdsf'
  
  URI_AGENCIES = 'http://ws.avendrealouer.fr/partenaires/1.25/ServicePartenaire.asmx/ListeAgencesPartenaire?CodePartenaire=%s&MotDePasse=%s'
  URI_GOODS = "http://ws.avendrealouer.fr/partenaires/1.25/ServicePartenaire.asmx/ListeAnnoncesAgence?CodePartenaire=%s&MotDePasse=%s&CodeAgence=%s"

  #waiting parameters : code_agence

  def create_uri
    return URI_GOODS % [PARTNER,CODE, @parameters["code_agence"].to_s]
  end  

  # Re-write scan files for aptalis importer
  # Delete the line with the date of call web service
  def scan_files
	Logger.send("warn","[APTALIS] Start scan files")
	@result[:description] << "[APTALIS] Start scan files"
    
	uri = create_uri
	Logger.send("warn","Loading from URI #{uri}")
	@result[:description] << "Loading from URI #{uri}"
	data = ""
    begin
      uriOpener = open(URI.encode(uri))
      data = uriOpener.read
      data.gsub!(/&([^ ;]{0,20}) /,"&amp;#{'\1'} ") #remplace le signe & par son equivalent HTML : &amp;
	  ### check if the file is a well formated xml ###
    rescue
	  Logger.send("warn","Failure: (#{$!})")
	  @result[:description] << "Failure: (#{$!})"
      return false
    end
	data.gsub!(/^.*<DateDerniereModificationAnnonce>.*<\/DateDerniereModificationAnnonce>.*$/,"")
    # check if the xlm returned by the uri have been already downloaded
	return unless ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest data)).first.nil?
    e = Execution.new
	e.passerelle = @passerelle
	e.statut = "nex"
	e.save!
	
	f = ExecutionSourceFile.from_data("data_file", data, e)
	
	e.execution_source_file = f
	e.save!
  end
  
  # Import/update good information
  def import_exe execution
    Logger.send("warn","[Aptalis] Starting Aptalis execution import")
	@result[:description] << "[Aptalis] Starting Aptalis execution import"
    	
    f = File.open(execution.execution_source_file.file.path)
    data = f.read
    hash = Hash.from_xml(data)
    
    # Create and list new goods
	return if hash['ArrayOfAgence']['Agence'].nil?
    return if hash['ArrayOfAgence']['Agence']['Annonces'].nil?
    goods = hash['ArrayOfAgence']['Agence']['Annonces']['Annonce']
    return if goods.nil?
	
	update_remote_medias
	
	Logger.send("warn","[Aptalis] #{goods.size} goods in XML stream.")
	@result[:description] << "[Aptalis] #{goods.size} goods in XML stream."
    goods.each { |b| import_bien b }
	
	maj_biens
    
    Logger.send("warn","[Aptalis] Finished Aptalis execution import")
	@result[:description] << "[Aptalis] Finished Aptalis execution import"
    return @result
  end

  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b['Ville']
	loc.ville = b['CodePostal']

	# Category & Transaction type
	cat = BienType.where(:nom => b['TypeBien'].to_s.titlecase).first
	if cat.nil?
		cat = BienType.new(:nom => b['TypeBien'].to_s.titlecase)
		cat.save!
	end
	transaction_type = BienTransaction.where(:nom => b['TypeTransaction'].to_s.titlecase).first
	return if transaction_type.nil?

	# find if good already exist, unless create it
	ref = b['Reference']       
	nb = Bien.where(:reference => ref).first
    nb = Bien.new if nb.nil?

	nb.is_accueil = false
	#nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)
	
	# update attributes
	nb.passerelle = @passerelle
	nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
	
	nb.nb_piece = b['NbPieces'].to_i
    nb.nb_chambre = b['NbChambres'].to_i
    nb.surface = b['SurfaceHabitable'].to_i
    nb.surface_terrain = b['SurfaceTerrain1'].to_i
    nb.titre = b['TypeBien'].to_s.titlecase
	
    nb.prix = b['Prix']
    nb.description = b['Texte']
    nb.valeur_dpe = b['Dpe_energie']
	nb.classe_dpe = b['Dpe_energie_etiquette']
	nb.valeur_ges = b['Dpe_emission_ges']
	nb.class_ges = b['Dpe_emission_ges_etiquette']
    nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b['Photos'] && b['Photos']['Photo']
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b['Photos']['Photo']
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
      pl.map { |p| import_remote_media(p['UrlOriginal'],p['Position'],nb) }
    end
    nb.save!

    return true

    return
  end
  
end