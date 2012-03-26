class Importers::Aftim < Importers::FromUrls
  
  URI_WEB_SERVICES = "http://www.aftim.fr/AftimService.svc?wsdl"

  SERVICE_CALLING = "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\"><s:Body><%s xmlns=\"http://tempuri.org/\"/></s:Body></s:Envelope>"
  
  #waiting parameters : service
  
  # Re-write scan files for afim importer (special webservices)
  def scan_files
	Logger.send("warn","[Aftim] Start scan files")
	@result[:description] << "[Aftim] Start scan files"

	client = Savon::Client.new{ wsdl.document = URI_WEB_SERVICES}

	servicename = @parameters["service"].to_s
	
	Logger.send("warn","Request on service #{servicename.camelcase}")
	@result[:description] << "Request on service #{servicename.camelcase}"
	
	data = ""
    begin
      service_calls = SERVICE_CALLING % [servicename.camelcase]
	
	  response = client.request(servicename.to_sym){soap.xml = service_calls}
	  h = response.to_hash
	  response = "#{servicename}_response"
	  result = "#{servicename}_result"
	  base = h[response.to_sym][result.to_sym]
	  data = Base64.decode64 base
	  ### check if the file is a well formated xml ###
    rescue
	  Logger.send("warn","Failure: (#{$!})")
	  @result[:description] << "Failure: (#{$!})"
      return false
    end
	
	return unless ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest data)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty?
    e = Execution.new
	e.passerelle = @passerelle
	e.statut = "nex"
	e.save!
	
	f = ExecutionSourceFile.from_data("data_file", data.force_encoding('utf-8'), e)
	
	e.execution_source_file = f
	e.save!
  end
  
  # Import/update good information
  def import_exe execution	
    Logger.send("warn","[Aftim] Starting Aftim execution import")
	@result[:description] << "[Aftim] Starting Aftim execution import"
    	
    f = File.open(execution.execution_source_file.file.path)
    data = f.read
    hash = Hash.from_xml(data)
    
    # Create and list new goods
	return if hash['ArrayOfWebServiceObject'].nil?
    goods = hash['ArrayOfWebServiceObject']['WebServiceObject']
    return if goods.nil?
	
	update_remote_medias
	
	Logger.send("warn","[Aftim] #{goods.size} goods in XML stream.")
	@result[:description] << "[Aftim] #{goods.size} goods in XML stream."
    goods.each { |b| import_bien b }
	
	maj_biens
    
    Logger.send("warn","[Aftim] Finished Aftim execution import")
	@result[:description] << "[Aftim] Finished Aftim execution import"
    return @result
  end

  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b['CodePostal']
	loc.ville = b['Ville']

	# Category & Transaction type
	cat = BienType.find_or_create b['Categorie'].up_first
	
	transaction_type = BienTransaction.where(:nom => b['TransactionType'].up_first).first
	return if transaction_type.nil?

	# find if good already exist, unless create it
	ref = b['Key']       
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?

	nb.is_accueil = false
	#nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)
	
	# update attributes
	nb.passerelle = @passerelle
	nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
	
	nb.nb_piece = b['NbPiece'].to_i if b['NbPiece'].kind_of? String or b['NbPiece'].kind_of? Integer
    nb.surface = b['Surface'].to_i if b['Surface'].kind_of? String or b['Surface'].kind_of? Integer
    nb.titre = b['TypeBien'].up_first
	
    nb.prix = b['Prix']
    nb.description = b['Description'].to_s+b['Descriptif'].to_s
    nb.valeur_dpe = b['DPEValeur'] if b['DPEValeur'].kind_of? String or b['DPEValeur'].kind_of? Integer
	nb.classe_dpe = b['DPELettre'] if b['DPELettre'].kind_of? String or b['DPELettre'].kind_of? Integer
	nb.valeur_ges = b['GESValeur'] if b['GESValeur'].kind_of? String or b['GESValeur'].kind_of? Integer
	nb.class_ges = b['GESLettre'] if b['GESLettre'].kind_of? String or b['GESLettre'].kind_of? Integer
    nb.statut = 'new'
    nb.save!
	
	photos = []
	9.times{ |i| 
		photos.push b["Img#{i}"] if b["Img#{i}"] && (b["Img#{i}"].kind_of? String) && !b["Img#{i}"].empty?
	}
	# If new images : Drop old images, add current images
    if not photos.empty?
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
      photos.map { |p| import_remote_media(p,(number+=1),nb) }
    end
    nb.save!

    return true

    return
  end
  
end