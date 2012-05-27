class Importers::Rom < Importers::FromFtp
  
  ROM_FTP_ADRESS = "azur-mediterranee.com"
  ROM_FTP_LOGIN = "virtualtouch"
  ROM_FTP_PASS = "tual3615ouch"
  ROM_FTP_FILE_REPO = "/data"
  ROM_FTP_MEDIA_REPO = "/data/import/photos"
  
  def initialize passerelle
    super passerelle, %w(text/csv), "csv", ROM_FTP_ADRESS, ROM_FTP_FILE_REPO, ROM_FTP_MEDIA_REPO
  end
  
  
  def import_exe execution
    Logger.send("warn","[Romazur] Starting execution import")
    @result[:description] << "[Romazur] Starting execution import"
	
    dl_and_update_medias
    
    f = File.open(execution.execution_source_file.file.path)
    data = f.read

    data = Iconv.conv('utf-8','cp1252',data.to_s)
    
      
    data.to_s.gsub!(/,/,"{virgule}")
    data.to_s.gsub!(/;/,",")
    
    csv_parsed = CSV.parse(data)
    csv_parsed.each{ |line| line.each{ |info| info.to_s.gsub!(/{virgule}/,",") } }
    import_hash(csv_parsed)
    
    f.close

    maj_biens
    
    Logger.send("warn","[Romazur] Finished execution import")
    @result[:description] << "[Romazur] Finished execution import"
    return @result
  end
  
  # Import a hash in Totalimmo tree format.
  
  def import_hash hashtree
	Logger.send("warn","[Romazur] Start CSV(hash) import")
	@result[:description] << "[Romazur] Start CSV(hash) import"

    # Create and list new goods
    @match_index_name = hashtree.first
    hashtree.delete hashtree.first
    hashtree.each { |b|
      import_bien b
    }
	
	Logger.send("warn","[Romazur] End CSV import")
	@result[:description] << "[Romazur] End CSV import"
    return true
  end
  
  def get_value value, hash
    return nil if @match_index_name.index(value).nil?
    return hash[@match_index_name.index(value)]
  end
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.ville = get_value("location",b)

	ref = get_value("reference",b)
	
	transaction_type = BienTransaction.where(:nom => 'Location').first
	price = nil
	
	cat = BienType.find_or_create get_value("type",b).up_first
    
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
	nb = Bien.new if nb.nil?
	
	desc = get_value("property_fr",b)
	desc = get_value("property",b) if desc.empty?
	nb.is_accueil = false

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    #nb.nb_piece = b["BIEN_NB_PIECE"]
    #nb.nb_chambre = b["BIEN_NB_CHAMBRE"]
    #nb.surface = b["BIEN_SURFACE_TOTALE"]
    #nb.surface_terrain = b["BIEN_SURFACE_TERRAIN"]
    #nb.titre = b["BIEN_LIBELLE"]
    nb.prix = price
    nb.description = desc
	
	nb.statut = 'new'
    nb.save!
	
	#nb.valeur_dpe = b["BIEN_CONSO_ENERGETIQUE"]
	#nb.valeur_ges = b["BIEN_EMISSION_GES"]
		
	# If new images : Drop old images, add current images
    lphotos = [get_value("liste_photo",b),get_value("photo",b),get_value("zoom",b)].select{ |p| !(p.nil? || p.empty?) }.join(",").split(",").select{ |p| !(p.nil? || p.empty?) }
    if !lphotos.empty?
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
	  number = 0
	  counter = 0
      lphotos.map { |p| import_local_media(p.to_s,(counter+=1),nb,p.to_s) }
    end
	
    nb.save!

    return
	end
	
  end