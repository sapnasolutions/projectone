class Importers::PagesimmoFtp < Importers::FromFiles

  #waiting parameters : code_agence
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  TOTAL_FTP_FOLDER = "pagesimmo/"
  
  def scan_files
    Logger.send("warn","[PagesimmoFtp] Start scan files")
	@result[:description] << "[PagesimmoFtp] Start scan files"
    
	unless File.exists? $base_ftp_repo+TOTAL_FTP_FOLDER
	  Logger.send("warn","[PagesimmoFtp] Directory #{TOTAL_FTP_FOLDER} does not exist.")
	  @result[:description] << "[PagesimmoFtp] Directory #{TOTAL_FTP_FOLDER} does not exist."
      return
    end
	
	# obtain a list of recent zips, sorted by modification time,
    # that can be opened as zipfiles, and save them
    pattern = File.join($base_ftp_repo+TOTAL_FTP_FOLDER, '*')
    Dir[pattern].sort { |a,b|
		File.mtime(a) <=> File.mtime(b)
    }.select{ |path|
      tmp_file = File.new(path,"r+b")
      filename = File.basename path
      nb_good_file = 0
      nb_file_read = 0
      # rescue if error during reading zipfile (ex : zip not found)
      begin
        z = Zip::ZipFile.open(path)
        z.each do |entry|
          nb_good_file += 1 if entry.name.to_s.downcase =~ /(#{@parameters["code_agence"].to_s}).*\.(jpg|jpeg|png|bmp)$/
          nb_file_read += 1
          break if nb_file_read >= 10
        end
        nb_good_file > 0
      rescue
        @logger.warn "Error during reading zip file : #{path}"
        false
      end
      ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty?
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
  # Import/update good information
  def import_exe execution
    Logger.send("warn","[PagesimmoFtp] Starting PagesimmoWs execution import")
    @result[:description] << "[PagesimmoFtp] Starting PagesimmoWs execution import"
    
    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

    dl_and_update_medias z

    z.each do |entry|
      next unless entry.name.downcase =~ /.cryptml$/
      data = z.read(entry)
      tree = Hash.from_xml(data)
	  import_hash(tree)
    end
    
    z.close
	
	maj_biens
    
    Logger.send("warn","[PagesimmoFtp] Finished PagesimmoWs execution import")
	@result[:description] << "[PagesimmoFtp] Finished PagesimmoWs execution import"
    return @result
  end

    def import_hash hashtree
	Logger.send("warn","[PagesimmoFtp] Start XML(hash) import")
	@result[:description] << "[PagesimmoFtp] Start XML(hash) import"

    goods = hashtree['ROOT']['DESTINATAIRE']['AGENCE']['BIEN']
    return if goods.nil?
    goods = [goods] unless goods.kind_of? Array
    # Create and list new goods
    goods.each { |b|
      import_bien b
    }
	
	Logger.send("warn","[PagesimmoFtp] End XML import")
	@result[:description] << "[PagesimmoFtp] End XML import"
    return true
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
    loc = BienEmplacement.new
    loc.pays = "France"
    loc.code_postal = b['LOCALISATION']['CP']
    loc.ville = b['LOCALISATION']['VILLE']

	# Category & Transaction type
    cat_text = find_cat(b)
    if(cat_text.nil? or b[cat_text].nil?)
	   Logger.send("warn","[PagesimmoFtp] Categorie non connue pour le bien ref : #{b["REFERENCE"]}")
	   @result[:description] << "[PagesimmoFtp] Categorie non connue pour le bien ref : #{b["REFERENCE"]}"
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
      b["LOCATION"]["PROVISIONS_CHARGES"] ||= 0
      price = b["LOCATION"]["LOYER_MENSUEL_TTC"].to_i + b["LOCATION"]["PROVISIONS_CHARGES"].to_i
    # elsif !(b["SAISONNIER"].nil?)
      # transaction_type = Immo::TransactionType.get 'Saisonnier'
      # transactionTypeIndex = "SAISONNIER"
      # price = 0
    else
	  Logger.send("warn","[PagesimmoFtp] Type de transaction nul pour le bien ref : #{b["REFERENCE"]}")
	  @result[:description] << "[PagesimmoFtp] Type de transaction nul pour le bien ref : #{b["REFERENCE"]}"
      return
    end

	# find if good already exist, unless create it
    ref = b["REFERENCE"]      
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
	
    nb.nb_piece = cat_root['NB_PIECES'].to_i
    nb.nb_chambre = cat_root['NB_CHAMBRES'].to_i
    nb.surface = cat_root['SURFACE_HABITABLE'].to_i
    nb.titre = cat_text
	
    nb.prix = price
    nb.description = b[transactionTypeIndex]["TEXTES"]["DESCRIPTION_FR"]
    if b['DIAGNOSTICS'] && b['DIAGNOSTICS']['DPE_CONSOMMATIONS_ENERGIE'] && b['DIAGNOSTICS']['DPE_CONSOMMATIONS_ENERGIE']['DONNEES']
      nb.valeur_dpe = b['DIAGNOSTICS']['DPE_CONSOMMATIONS_ENERGIE']['DONNEES']['VALEUR']
      nb.classe_dpe = b['DIAGNOSTICS']['DPE_CONSOMMATIONS_ENERGIE']['DONNEES']['LETTRE']
    elsif b['DPE_ENERGIE']
      nb.valeur_dpe = b['DPE_ENERGIE']['VALEUR']
      nb.classe_dpe = b['DPE_ENERGIE']['LETTRE']
    end
    if b['DIAGNOSTICS'] && b['DIAGNOSTICS']['DPE_EMISSIONS_GES'] && b['DIAGNOSTICS']['DPE_EMISSIONS_GES']['DONNEES']
      nb.valeur_ges = b['DIAGNOSTICS']['DPE_EMISSIONS_GES']['DONNEES']['VALEUR']
      nb.class_ges = b['DIAGNOSTICS']['DPE_EMISSIONS_GES']['DONNEES']['LETTRE']
    elsif b['DPE_CO2']
      nb.valeur_ges = b['DPE_CO2']['VALEUR']
      nb.class_ges = b['DPE_CO2']['LETTRE']
    end
    nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b['FICHIER']
      pl = b['FICHIER']
      pl = [pl] unless pl.kind_of? Array
      if b['FICHIER'].first['FICHIER_JOINT']
        list_hash = pl.select{ |pf| pf['INDICE'].to_i != 0 && pf['FICHIER_JOINT'] && pf['FICHIER_JOINT']['NOM_FICHIER'] && !pf['FICHIER_JOINT']['NOM_FICHIER'].empty? }
        if !list_hash.empty?        
          list_img = list_hash.map{ |ih| ih['FICHIER_JOINT']['NOM_FICHIER'] }
          # un-attach old
          nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
          }
          # Map photo-hashes to medias, filter out failures, and add medias to good
          counter = 0
          list_img.map{ |p| import_local_media(p.to_s,(counter+=1),nb,p.to_s) }
        end
      end
    end
    nb.save!

    return true

    return
  end
  
end