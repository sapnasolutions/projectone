class Importers::Ac3 < Importers::FromUrls
  
  URI_GOODS = "http://batch.ac3-distribution.com/office/%s/cache/export.xml"
  CAT_TYPES = ["APPARTEMENT","MAISON","DEMEURE_CHATEAU","TERRAIN","PARKING_GARAGE","IMMEUBLE","LOCAL_COMMERCIAL"]
  #waiting parameters : code_agence

  def create_uri
    return URI_GOODS % [@parameters["code_agence"].to_s]
  end  
  
  # Import/update good information
  def import_exe execution
    Logger.send("warn","[AC3] Starting AC3 execution import")
	@result[:description] << "[AC3] Starting AC3 execution import"
    	
    f = File.open(execution.execution_source_file.file.path)
	    # f = File.open(execution.execution_source_file.file.path,"r:ascii-8bit:utf-8")
    data = f.read
    hash = Hash.from_xml(data)
    
    # Create and list new goods
	return if hash.nil?
	return if hash['LISTEPA'].nil?
    goods = hash['LISTEPA']['BIEN']
    return if goods.nil?
	
	update_remote_medias
	
	Logger.send("warn","[AC3] #{goods.size} goods in XML stream.")
	@result[:description] << "[AC3] #{goods.size} goods in XML stream."
    goods.each { |b| import_bien b }
	
	maj_biens
    
    Logger.send("warn","[AC3] Finished AC3 execution import")
	@result[:description] << "[AC3] Finished AC3 execution import"
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
		loc.code_postal = b['LOCALISATION']['VILLE']
		loc.ville = b['LOCALISATION']['CODE_POSTAL']
	else
		loc = nil
	end

	# Category & Transaction type
	cat_text = find_cat(b)
    if(cat_text.nil? or b[cat_text].nil?)
	   Logger.send("warn","[AC3] Categorie non connue pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}")
	   @result[:description] << "[AC3] Categorie non connue pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}"
       return
    end
	cat_root = b[cat_text]
	cat = BienType.find_or_create cat_text.up_first
	
	Logger.send("warn","Categorie : #{cat_text}")
	
	if !(b["VENTE"].nil?)
	  transaction_type = BienTransaction.where(:nom => 'Vente').first
      transactionTypeIndex = "VENTE"
      price = b["VENTE"]["PRIX"]
    elsif !(b["LOCATION"].nil?)
      transaction_type = BienTransaction.where(:nom => 'Location').first
      transactionTypeIndex = "LOCATION"
      b["LOCATION"]["PROVISION_SUR_CHARGES"] ||= 0
      price = b["LOCATION"]["LOYER"].to_i + b["LOCATION"]["PROVISION_SUR_CHARGES"].to_i
    # elsif !(b["SAISONNIER"].nil?)
      # transaction_type = Immo::TransactionType.get 'Saisonnier'
      # transactionTypeIndex = "SAISONNIER"
      # price = 0
    else
	  Logger.send("warn","[AC3] Type de transaction nul pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}")
	  @result[:description] << "[AC3] Type de transaction nul pour le bien ref : #{b["INFO_GENERALES"]["AFF_NUM"]}"
      return
    end

	# find if good already exist, unless create it
	ref = b["INFO_GENERALES"]["AFF_NUM"]      
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
	
	nb.nb_piece = cat_root['NBRE_PIECES'].to_i
    nb.nb_chambre = cat_root['NBRE_CHAMBRES'].to_i
    nb.surface = cat_root['SURFACE_HABITABLE'].to_i
    nb.surface_terrain = cat_root['SURFACE_TERRAIN'].to_i
    nb.titre = b['INTITULE']['FR']
	
    nb.prix = price
    nb.description = b['COMMENTAIRES']['FR']
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