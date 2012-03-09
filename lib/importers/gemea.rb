class Importers::Gemea < Importers::FromUrls  

  require "xmlsimple"

  URI_GOODS = "http://%s/specific_files/data.xml"

  #waiting parameters : baseuri

  def create_uri
    return URI_GOODS % [@parameters["baseuri"].to_s]
  end
  
  # Import/update good information
  def import_exe execution
    Logger.send("warn","[Gemea] Starting Gemea execution import")
	@result[:description] << "[Gemea] Starting Gemea execution import"
    	
    f = File.open(execution.execution_source_file.file.path)
    data = f.read
    hash = XmlSimple.xml_in(data)
    
    # Create and list new goods
	return if hash.nil?
    goods = hash["product"]
    return if goods.nil?
	
	update_remote_medias
	
	Logger.send("warn","[Gemea] #{goods.size} goods in XML stream.")
	@result[:description] << "[Gemea] #{goods.size} goods in XML stream."
    goods.each { |b| import_bien b }
	
	maj_biens
    
    Logger.send("warn","[Gemea] Finished Gemea execution import")
	@result[:description] << "[Gemea] Finished Gemea execution import"
    return @result
  end

  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
	ville = b["name"].first["name"].select{ |h| h["lang"] == "fr" }.first
	if ville
		loc = BienEmplacement.new
		loc.pays = "France"
		loc.ville = ville['content']
	else
		loc = nil
	end

	# Category & Transaction type
	catNtrans = b["category"].first["content"]
	catname = catNtrans.split(" ").second
	trans = catNtrans.split(" ").first
	cat = BienType.find_or_create catname.up_first
	
	if trans == "Ventes"
		transaction_type = BienTransaction.where(:nom => "Vente").first
	elsif trans == "Locations"
		transaction_type = BienTransaction.where(:nom => "Location").first
	else
		return
	end
	# find if good already exist, unless create it
	ref = b["reference"].first
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?

	nb.is_accueil = false
	#nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)
	
	# update attributes
	nb.passerelle = @passerelle
	nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc if loc
	
    nb.titre = catname.up_first
	
    nb.prix = b["prix"].first["content"].to_i
    desc = b["description"].first["description"].select{ |h| h["lang"] == "fr" }.first
	if ville
		nb.description = desc['content']
	else
		nb.description = ""
	end
	if b["dpe_eco"].first.kind_of? Hash
		nb.valeur_dpe = 0
	else
		nb.valeur_dpe = b["dpe_eco"].first
	end
	if b["dpe_ges"].first.kind_of? Hash
		nb.valeur_ges = 0
	else
		nb.valeur_ges = b["dpe_ges"].first
	end
	
    nb.statut = 'new'
    nb.save!
	
	p_urls = []
	10.times{ |i| 
		p_urls.push b["picture#{i}"].first if (b["picture#{i}"].first.kind_of? String) && !b["picture#{i}"].first.empty?
	}
	# If new images : Drop old images, add current images
    if !p_urls.empty?
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
      p_urls.map { |p| import_remote_media(p,(number+=1),nb) }
    end
    nb.save!

    return true

    return
  end
  
end