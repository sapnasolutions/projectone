class Importers::Goventis < Importers::FromFiles
  require 'zip/zipfilesystem'
  
  def initialize passerelle
    super passerelle, %w(application/zip)
  end

  # Import a ZIP file containing Goventis-formatted XML and images to the database
  def import_exe execution
	Logger.send("warn","[Goventis] Starting execution import")
	@result[:description] << "[Goventis] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

    dl_and_update_medias z

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
      data = z.read(entry)
      tree = Hash.from_xml(data)
      @mapTable = Hash.new
	  import_hash(tree)
    end

    z.close

    maj_biens
    
	Logger.send("warn","[Goventis] Finished execution import")
	@result[:description] << "[Goventis] Finished execution import"
    return @result
  end

  # Import a hash in Goventis tree format.
  # Return the list of agencies in the tree.
  def import_hash hashtree
	Logger.send("warn","Start XML(hash) import")
	@result[:description] << "Start XML(hash) import"

	# Create and list new goods
    hashtree["Affaires"]["Affaire"].each { |b|
      next unless b.kind_of? Hash
      import_bien b
    }
	
	Logger.send("warn","End XML import")
	@result[:description] << "End XML import"
    return true
  end

   # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = nil	
	loc.ville = b["Affaire_ville"].to_s.titlecase
	
	transaction_type = BienTransaction.where(:nom => b['Affaire_type_annonce'].titlecase).first
	price = b["Affaire_prix"].to_i
    
	ref = b["Affaire_reference"]
	nb = Bien.where(:reference => ref).first
    nb = Bien.new if nb.nil?

	cat = BienType.where(:nom => b['Affaire_type_bien'].titlecase).first
	if cat.nil?
		cat = BienType.new(:nom => b['Affaire_type_bien'].titlecase)
		cat.save!
	end
	
	desc = b["Affaire_desc_magazine"]
    if desc.blank?
      desc = b["Affaire_desc_internet"]
    end
	if b["Affaire_honoraires"] && b["Affaire_honoraires"].to_i > 0
		desc << "[sdl]Honoraires Agence : #{b["Affaire_honoraires"]} [euro]"
	end
	
	nb.is_accueil = false
	
    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["Affaire_nb_piece"]
    nb.nb_chambre = b["Affaire_nb_chambre"]
    nb.surface = b["Affaire_surface_habitable"]
    nb.surface_terrain = b["Affaire_surface_terrain"]
    nb.titre = b['Affaire_type_bien']
    nb.prix = price
    nb.description = desc
	
    nb.valeur_dpe = b["Affaire_consommation_energie"]
	# nb.classe_dpe = b["DPE_ETIQ1"]
	
	# nb.valeur_ges = b["DPE_VAL2"]
	# nb.class_ges = b["DPE_ETIQ2"]
	
    nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b['Affaire_images'] && b['Affaire_images']['image']
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b['Affaire_images']['image']
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  counter = 0
	  pl.map { |p| import_local_media(p.to_s,(counter += 1), nb,p.to_s) }
    end
	
    nb.save!

    return
  end
  
end