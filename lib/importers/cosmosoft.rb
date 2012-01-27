class Importers::Cosmosoft < Importers::FromUrls
  # PARTNER = 'HILABS'
  # CODE = '678jksq5'
  
  URI_GOODS = "http://www.cosmosoft.fr/cosmoAPI/passerelle/passerelle.php?xi=%s"

  #waiting parameters : code_agence

  def create_uri
    return URI_GOODS % [@parameters["code_agence"].to_s]
  end  

  # Re-write scan files for Cosmosoft importer
  # Delete the line with the date of call web service
  def scan_files
	Logger.send("warn","[Cosmosoft] Start scan files")
	@result[:description] << "[Cosmosoft] Start scan files"
    
	uri = create_uri
	Logger.send("warn","Loading from URI #{uri}")
	@result[:description] << "Loading from URI #{uri}"
	data = ""
    begin
      uriOpener = open(URI.encode(uri),"r:utf-8")
	  data =  uriOpener.read
	  ### check if the file is a well formated xml ###
    rescue
	  Logger.send("warn","Failure: (#{$!})")
	  @result[:description] << "Failure: (#{$!})"
      return false
    end
	data.gsub!(/date="[^"]*"/,"")
    # check if the xlm returned by the uri have been already downloaded
	return unless ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest data)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty?
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
    Logger.send("warn","[Cosmosoft] Starting Cosmosoft execution import")
	@result[:description] << "[Cosmosoft] Starting Cosmosoft execution import"
    	
    f = File.open(execution.execution_source_file.file.path)
    data = f.read
    hash = Hash.from_xml(data)
    
    # Create and list new goods
	return if hash['xml']['Export'].nil?
	return if hash['xml']['Export']['Agence'].nil?
    return if hash['xml']['Export']['Agence']['Affaire'].nil?
    goods = hash['xml']['Export']['Agence']['Affaire']
	
	goods = [goods] unless goods.kind_of? Array
	
	update_remote_medias
	
	Logger.send("warn","[Cosmosoft] #{goods.size} goods in XML stream.")
	@result[:description] << "[Cosmosoft] #{goods.size} goods in XML stream."
    goods.each { |b| import_bien b }
	
	maj_biens
    
    Logger.send("warn","[Cosmosoft] Finished Cosmosoft execution import")
	@result[:description] << "[Cosmosoft] Finished Cosmosoft execution import"
    return @result
  end

  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b['BienCP']
	loc.ville = b['BienVille']

	# Category & Transaction type
	cat = BienType.find_or_create b['TypeAffaire'].up_first
	
	if b['TypeTransaction'] == "Vente de bien"
		transaction_type = BienTransaction.where(:nom => "Vente").first
	else
		transaction_type = BienTransaction.where(:nom => "Location").first
	end
	return if transaction_type.nil?

	# find if good already exist, unless create it
	ref = b['RefAnnonce']       
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
    nb.surface = b['SurfHab'].to_i
    nb.surface_terrain = b['SurfTerrain'].to_i
    nb.titre = b['TypeAffaire'].up_first
	
    nb.prix = b['PrixMandatEuro']
    nb.description = b['TextePub']
    nb.valeur_dpe = b['DPEValeur']
	nb.classe_dpe = b['DPELettre']
	nb.valeur_ges = b['GESValeur']
	nb.class_ges = b['GESLettre']
    nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b['Photo']
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = [b['Photo']]
	  20.times{ |i|
		pl.push b["Photo_#{i+1}"] unless b["Photo_#{i+1}"].nil? or b["Photo_#{i+1}"].empty?
	  }

      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
      pl.map { |p| import_remote_media(p.to_s,(number+=1),nb) }
    end
    nb.save!

    return true

    return
  end
  
end