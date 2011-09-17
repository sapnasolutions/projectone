class Importers::Ubiflow < Importers::FromFiles
  
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  def import_exe execution
	Logger.send("warn","[Ubiflow] Starting execution import")
	@result[:description] << "[Ubiflow] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

	update_remote_medias

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
      data = z.read(entry)
      tree = Hash.from_xml(data)
	  
      @mapTable = Hash.new #pas obligatoire
	  
	  import_hash(tree)
    end
    
    z.close

    maj_biens
    
	Logger.send("warn","[Ubiflow] Finished execution import")
	@result[:description] << "[Ubiflow] Finished execution import"
    return @result
  end
  
  # Import a hash in Ubiflow tree format.
  
  def import_hash hashtree
	Logger.send("warn","[Ubiflow] Start XML(hash) import")
	@result[:description] << "[Ubiflow] Start XML(hash) import"

    # Create and list new goods
    hashtree["client"]["annonce"].each { |b|
      import_bien b
    }
	
	Logger.send("warn","[Ubiflow] End XML import")
	@result[:description] << "[Ubiflow] End XML import"
    return true
  end
  
  cat_code_matching = []
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b["bien"]["code_postal"]
	loc.ville = b["bien"]["ville"]

	ref = b["reference"]
	
	#############################
	# a faire
	cat_code = b["bien"]["code_type"]
	cat = cat_code_matching[cat_code]
	
	cat = BienType.where(:nom => b["CATEGORIE"].to_s.titlecase).first
	if cat.nil?
		cat = BienType.new(:nom => b["CATEGORIE"].to_s.titlecase)
		cat.save!
	end
	
	# b["bien"][""]
	
	# Determine if the good is a sell or a rent
	price = b["PRIX"].to_i
    if b["prestation"]["type"] == "V"
      transaction_type = BienTransaction.where(:nom => 'Vente').first
    elsif b["prestation"]["type"] == "L"
	  transaction_type = BienTransaction.where(:nom => 'Location').first
    else
		Logger.send("warn","Type de transaction inconnue : #{b["prestation"]["type"]} pour le bien ref : #{ref}")
		@result[:description] << "Type de transaction inconnue : #{b["prestation"]["type"]} pour le bien ref : #{ref}"
        return false
      end
    end
    
	nb = Bien.where(:reference => ref).first
    nb = Bien.new if nb.nil?
	
	desc = b["texte"]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["bien"]["nb_pieces"]
    nb.nb_chambre = b["bien"]["nb_chambres"]
    nb.surface = b["bien"]["surface"]
    nb.surface_terrain = b["bien"]["surface_terrain"]
    nb.titre = b["titre"]
    nb.prix = price
    nb.description = desc
	
    nb.valeur_dpe = b["bien"]["diagnostiques"]["dpe_valeur_conso"]
	nb.classe_dpe = b["bien"]["diagnostiques"]["dpe_etiquette_conso"]
	
	nb.valeur_ges = b["bien"]["diagnostiques"]["dpe_valeur_ges"]
	nb.class_ges = b["bien"]["diagnostiques"]["dpe_etiquette_ges"]
	
	##############
	# a faire les photos aussi
	
    nb.statut = 'new'
    nb.save!

    return
  end

end