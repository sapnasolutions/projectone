class Importers::Nexto < Importers::FromUrls
  
  URI_GOODS = "http://www.burger-sothebysrealty.com/tmp/virtualtouch/export_virtualtouch.xml"

  #waiting parameters : code_agence

  def create_uri
    return URI_GOODS
  end  

  # Import/update good information
  def import_exe execution
    Logger.send("warn","[Nexto] Starting Nexto execution import")
	@result[:description] << "[Nexto] Starting Nexto execution import"
    	
    f = File.open(execution.execution_source_file.file.path)
    data = f.read
    hash = Hash.from_xml(data)
    
    # Create and list new goods
	agencies = hash['agencies']['agency'] 
	return if agencies.nil?
	agency = agencies.select{|a| a["agencycode"].to_s == @parameters["code_agence"].to_s}.first
	return if agency.nil?
    goods = agency['properties']['property']
    return if goods.nil?
	
	update_remote_medias
	
	Logger.send("warn","[Nexto] #{goods.size} goods in XML stream.")
	@result[:description] << "[Nexto] #{goods.size} goods in XML stream."
    goods.each { |b| import_bien b }
	
	maj_biens
    
    Logger.send("warn","[Nexto] Finished Nexto execution import")
	@result[:description] << "[Nexto] Finished Nexto execution import"
    return @result
  end

  # Create a new good, and return the ActiveRecord
  def import_bien b

	return if b["forsale"].to_i != 1

	# Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b['postalcode']
	loc.ville = b['city']
	
	# Category & Transaction type
	cat = BienType.find_or_create b['type'].up_first
	
	transaction_type = BienTransaction.where(:nom => "Vente").first
	return if transaction_type.nil?

	# find if good already exist, unless create it
	ref = b['id']       
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
	
    nb.nb_chambre = b['bedrooms'].to_i
    nb.titre = b['name']
	
    nb.prix = b['sale_price'].to_i if b['sale_price'].to_s != "Nous consulter"
    nb.description = b['description']
    nb.valeur_dpe = b['dpe']
	nb.valeur_ges = b['ges']
    nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b['images'] && b['images']['image']
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b['images']['image']
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
      pl.map { |p| import_remote_media(p['url'],(number+=1),nb) }
    end
    nb.save!

    return true

    return
  end
  
end