class Importers::PagesimmoWs < Importers::FromUrls
  
  URI_GOODS_PI_WS = "http://v2.gercop-transac.net/office2/%s/cache/export.xml"

  #waiting parameters : code_agence

  def create_uri
    return URI_GOODS_PI_WS % [@parameters["code_agence"].to_s]
  end  

  # Re-write scan files for PagesimmoWs importer
  # Delete the line with the date of call web service
  def scan_files
	Logger.send("warn","[PagesimmoWs] Start scan files")
	@result[:description] << "[PagesimmoWs] Start scan files"
    
	uri = create_uri
	Logger.send("warn","Loading from URI #{uri}")
	@result[:description] << "Loading from URI #{uri}"
	data = ""
    begin
      uriOpener = open(URI.encode(uri),"r:utf-8",{:read_timeout => 1800})
      data = uriOpener.read
	  ### check if the file is a well formated xml ###
    rescue
	  Logger.send("warn","Failure: (#{$!})")
	  @result[:description] << "Failure: (#{$!})"
      return false
    end
	#data.gsub!(/^.*<DATE_CREATION>.*<\/DATE_CREATION>.*$/,"")
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
    Logger.send("warn","[PagesimmoWs] Starting PagesimmoWs execution import")
	@result[:description] << "[PagesimmoWs] Starting PagesimmoWs execution import"
    	
    f = File.open(execution.execution_source_file.file.path)
    data = f.read
    hash = Hash.from_xml(data)
    
    # Create and list new goods
    goods = hash['LISTEPA']['BIEN']
    return if goods.nil?
    goods = [goods] unless goods.kind_of? Array
	
    update_remote_medias
	
    Logger.send("warn","[PagesimmoWs] #{goods.size} goods in XML stream.")
    @result[:description] << "[PagesimmoWs] #{goods.size} goods in XML stream."
    goods.each { |b| import_bien b }
	
	maj_biens
    
    Logger.send("warn","[PagesimmoWs] Finished PagesimmoWs execution import")
	@result[:description] << "[PagesimmoWs] Finished PagesimmoWs execution import"
    return @result
  end

  def find_cat(b)
    ["APPARTEMENT","MAISON","DEMEURE_CHATEAU","TERRAIN","PARKING_GARAGE","IMMEUBLE","LOCAL_COMMERCIAL"].each { |cat|
        return cat unless b[cat].nil?
    }
    return nil
  end
  
  # Create a new good, and return the ActiveRecord
  def import_bien b
  
    # Good location
    good_address = {}
    if b['LOCALISATION']['VISIBLE'].to_s == "true"
            loc = BienEmplacement.new
            loc.pays = "France"
            loc.code_postal = b['LOCALISATION']['CODE_POSTAL']
            loc.ville = b['LOCALISATION']['VILLE']
    else
            loc = nil
    end
    description = ""
	# Category & Transaction type
    cat_text = find_cat(b)
    if(cat_text.nil? or b[cat_text].nil?)
	   Logger.send("warn","[PagesimmoWs] Categorie non connue pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}")
	   @result[:description] << "[PagesimmoWs] Categorie non connue pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}"
       return
    end
	cat_root = b[cat_text]
	cat = BienType.find_or_create cat_text.up_first
	
	if !(b["VENTE"].nil?)
	  transaction_type = BienTransaction.where(:nom => 'Vente').first
      transactionTypeIndex = "VENTE"
      price = b["VENTE"]["PRIX"]
    elsif !(b["LOCATION"].nil?)
      transaction_type = BienTransaction.where(:nom => 'Location').first
      transactionTypeIndex = "LOCATION"
      b["LOCATION"]["PROVISION_SUR_CHARGES"] ||= 0
      price = b["LOCATION"]["LOYER"].to_i + b["LOCATION"]["PROVISION_SUR_CHARGES"].to_i
      description = "Honoraires agence #{b["LOCATION"]["FRAIS_AGENCE"].to_i} euros" if b["LOCATION"]["FRAIS_AGENCE"].to_i > 0
    # elsif !(b["SAISONNIER"].nil?)
      # transaction_type = Immo::TransactionType.get 'Saisonnier'
      # transactionTypeIndex = "SAISONNIER"
      # price = 0
    else
	  Logger.send("warn","[PagesimmoWs] Type de transaction nul pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}")
	  @result[:description] << "[PagesimmoWs] Type de transaction nul pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}"
      return
    end

	# find if good already exist, unless create it
	ref = b["INFO_GENERALES"]["AFF_NUM"]      
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
	
	nb.nb_piece = cat_root['NBRE_PIECES'].to_i
    nb.nb_chambre = cat_root['NBRE_CHAMBRES'].to_i
    nb.surface = cat_root['SURFACE_HABITABLE'].to_i
    nb.surface_terrain = cat_root['SURFACE_TERRAIN'].to_i
    #nb.titre = b['INTITULE']['FR']
	
    nb.prix = price
    nb.description = b['COMMENTAIRES']['FR']+" "+description
    nb.valeur_dpe = cat_root['CONSO_ANNUEL_ENERGIE']
	nb.classe_dpe = cat_root['CONSOMMATIONENERGETIQUE']
	nb.valeur_ges = cat_root['VALEUR_GES']
	nb.class_ges = cat_root['GAZEFFETDESERRE']
    nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b['IMAGES'] && b['IMAGES']['IMG']
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b['IMAGES']['IMG']
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
      pl.map { |p| import_remote_media(p,(number += 1),nb) }
    end
    nb.save!

    return true

    return
  end
  
end