class Importers::Trans21 < Importers::FromFiles
  
  def initialize passerelle
    super passerelle, %w(application/zip)
  end

  #waiting parameters : code_agence
  #login : rault
  #pass : ar4hf4UdIl
  UBI_FTP_FOLDER = "trans21/"
  
  #Import only file who's named 'c21.zip'
  def scan_files
    Logger.send("warn","[FILE] Start scan files")
	@result[:description] << "[FILE] Start scan files"
    
	unless File.exists? $base_ftp_repo+UBI_FTP_FOLDER
	  Logger.send("warn","[FILE] Directory #{UBI_FTP_FOLDER} does not exist.")
	  @result[:description] << "[FILE] Directory #{UBI_FTP_FOLDER} does not exist."
      return
    end
	
	# obtain a list of recent zips, sorted by modification time,
    # that can be opened as zipfiles, and save them
    pattern = File.join($base_ftp_repo+UBI_FTP_FOLDER, '*')
    Dir[pattern].sort { |a,b|
		File.mtime(a) <=> File.mtime(b)
    }.select{ |path|
		tmp_file = File.new(path,"r+b")
		filename = File.basename path
        ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty? && filename =~ /c21.zip/
	}.each { |path|
	# self.from_file(filename,file,execution)
		name = path
		tmp_file = File.new(path,"r+b")
		e = Execution.new
		e.passerelle = @passerelle
		e.statut = "nex"
		e.save!
		f = ExecutionSourceFile.from_file(name,tmp_file,e)
		e.execution_source_file = f
		e.save!
    }
  end
  
  def import_exe execution
	Logger.send("warn","[Trans21] Starting execution import")
	@result[:description] << "[Trans21] Starting execution import"

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

	update_remote_medias

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
	  
	  data = z.read(entry)
      tree = Hash.from_xml(data)
      return if tree.nil? || tree["root"].nil? || tree["root"]["agence"].nil? || tree["root"]["biens"].nil?
      import_hash(tree)
    end
    
    z.close

    maj_biens
    
	Logger.send("warn","[Trans21] Finished execution import")
	@result[:description] << "[Trans21] Finished execution import"
    return @result
  end

  # def agency_belongs_to_client? a
    # return a["code_agence"] && a["code_agence"] != "" && (@app.parameter.split("|").include? a["code_agence"])
  # end
  
  def goods_list_belongs_to_gateway? goods_list
    goods_list.each { |b|
      if b["euid_bien"] && b["euid_bien"] != ""
		  if b["euid_bien"].split("_").first == @parameters["code_agence"].split("_").first && b["euid_bien"].split("_").second == @parameters["code_agence"].split("_").second
			return true
		  end
      end
    }
    return false
  end

  # Import a hash in Trans21 tree format.
  def import_hash hashtree
	Logger.send("warn","[Trans21] Start XML(hash) import")
	@result[:description] << "[Trans21] Start XML(hash) import"

	agencies = hashtree["root"]["agence"]
    agencies = [agencies] unless agencies.kind_of? Array
    goods_lists = hashtree["root"]["biens"]
    goods_lists = [goods_lists] unless goods_lists.kind_of? Array
	
	# Actually not used, un-comment and re-adapt if agencies management
	# agencies.each { |a|
      # import_agency a if agency_belongs_to_client? a
    # }
	
	# Create and list new goods
    goods_lists.each { |gl|
      goods_list = gl["bien"]
      goods_list = [goods_list] unless goods_list.kind_of? Array
      if(goods_list && (goods_list_belongs_to_gateway? goods_list))
          goods_list.each { |b|
            import_bien b
          }
      end
    }

	Logger.send("warn","[Trans21] End XML import")
	@result[:description] << "[Trans21] End XML import"
    return true
  end

  # def import_agency a
    ##Agency and its location
    # source_key = "trans21-" + a["code_agence"]
    # agency = Immo::Agency.get source_key
    # agency.name    = a["nom"].to_s.titlecase
    # agency.phone   = a["telephone"]
    # agency.email   = a["email"]
    ##agency.website = ???

    # address = {}
    # address[:address]  = a["adresse"]
    # address[:city]     = a["ville"]
    # address[:zipcode]  = a["code_postal"]
    # address[:country]  = "France"
    # agency.location    = Immo::Location.get address

    # agency.save!
  # end


  # Create a new good, and return the ActiveRecord
  def import_bien b
  
	# Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.ville = b["ville"].up_first

	ref = b["reference"]
	
	cat = BienType.find_or_create b['type_bien'].up_first
	
	# Determine if the good is a sell or a rent
    if b['type_transaction'] == "vente"
      transaction_type = BienTransaction.where(:nom => 'Vente').first
    elsif b['type_transaction'] == "location"
	  transaction_type = BienTransaction.where(:nom => 'Location').first
    else
		Logger.send("warn","Type vente | location null pour le bien ref : "+b["ref"])
		@result[:description] << "Type vente | location null pour le bien ref : "+b["ref"]
        return false
    end
	price = b["prix"].to_i
	
	nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?
	
	desc = b["desc_fr"]
	nb.is_accueil = false
	# nb.is_accueil = true if b["TEXTE_MAILING"] && (b["TEXTE_MAILING"].to_s.downcase =~ /.*virtual.*touch.*/)

	nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["nb_piece"]
    nb.nb_chambre = b["nb_chambre"]
    nb.surface = b["surf_hab"]
    nb.surface_terrain = b["surf_terrain"]
    nb.titre = cat.nom
    nb.prix = price
    nb.description = desc
	
	nb.valeur_dpe = b["valeur_dpe"]
	nb.classe_dpe = b["lettre_dpe"]	
	nb.valeur_ges = b["valeur_ges"]
	nb.class_ges = b["lettre_ges"]
		
	nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b["photos"] && b["photos"]["photo"]
      # un-attach old
	  nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
	 }
      pl = b["photos"]["photo"]
      
      # When there only exists a single image, +pl+ will directly be the hash
      pl = [pl] unless pl.kind_of? Array
      # Map photo-hashes to medias, filter out failures, and add medias to good
	  number = 0
	  counter = 0
      pl.map { |p| import_remote_media(p["url_photo"].to_s,(counter+=1),nb) }
    end
	
    nb.save!

    return
  end
  
  
end