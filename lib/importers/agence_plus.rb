class Importers::AgencePlus < Importers::FromFiles

  #waiting parameters : code_agence
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  TOTAL_FTP_FOLDER = "agenceplus/"
  
  def scan_files
    Logger.send("warn","[AgencePlus] Start scan files")
	@result[:description] << "[AgencePlus] Start scan files"
    
	unless File.exists? $base_ftp_repo+TOTAL_FTP_FOLDER
	  Logger.send("warn","[AgencePlus] Directory #{TOTAL_FTP_FOLDER} does not exist.")
	  @result[:description] << "[AgencePlus] Directory #{TOTAL_FTP_FOLDER} does not exist."
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
        ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty? && filename =~ /#{@parameters["code_agence"]}\.zip/
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
    Logger.send("warn","[AgencePlus] Starting PagesimmoWs execution import")
    @result[:description] << "[AgencePlus] Starting PagesimmoWs execution import"
    
    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

    dl_and_update_medias z

    z.each do |entry|
      next unless entry.name.downcase =~ /.xml$/
      data = z.read(entry)
      tree = Hash.from_xml(data)
      import_hash(tree)
    end
    
    z.close
	
	maj_biens
    
    Logger.send("warn","[AgencePlus] Finished AgencePlus execution import")
	@result[:description] << "[AgencePlus] Finished AgencePlus execution import"
    return @result
  end

    def import_hash hashtree
	Logger.send("warn","[AgencePlus] Start XML(hash) import")
	@result[:description] << "[AgencePlus] Start XML(hash) import"

    goods = hashtree['export']['Agence']['Biens']['Bien']
    return if goods.nil?
    goods = [goods] unless goods.kind_of? Array
    # Create and list new goods
    goods.each { |b|
      import_bien b
    }
	
	Logger.send("warn","[AgencePlus] End XML import")
	@result[:description] << "[AgencePlus] End XML import"
    return true
  end
  
  # Create a new good, and return the ActiveRecord
  def import_bien b
  
    # Good location
    good_address = {}
    loc = BienEmplacement.new
    loc.pays = "France"
    loc.code_postal = b['BienAddress']['Zipcode']
    loc.ville = b['BienAddress']['ZipcodeCity']

    cat = BienType.find_or_create b['Category'].up_first

    transaction_type = BienTransaction.where(:nom => b["TransactionType"].up_first).first
    if transaction_type.nil?
	  Logger.send("warn","[AgencePlus] Type de transaction non connnu pour le bien ref : #{b["MandatNum"]}")
	  @result[:description] << "[AgencePlus] Type de transaction non connnu pour le bien ref : #{b["MandatNum"]}"
      return
    end

	# find if good already exist, unless create it
    ref = b["MandatNum"].to_s
    nb = Bien.where(:reference => ref).select{ |b| b.passerelle.installation == @passerelle.installation }.first
    nb = Bien.new if nb.nil?

    nb.is_accueil = false
    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
	
    nb.nb_piece = b['NbRooms'].to_i
    nb.nb_chambre = b['NbChbs'].to_i
    nb.surface = b['Surface'].to_i
    nb.titre = b['Type'].to_s
	
    nb.prix = b['SoldPrice']
    if b['Descriptions'] && b['Descriptions']['Description']
      desc = b['Descriptions']['Description']
      desc = [desc] unless desc.kind_of? Array
      nb.description = desc.first
    end
    
    
    nb.valeur_dpe = b['DPE']['PE'] if b['DPE'] && b['DPE']['PE']
    nb.classe_dpe = b['DPE']['PE_letter'] if b['DPE'] && b['DPE']['PE_letter']
  
    nb.valeur_ges = b['DPE']['GES'] if b['DPE'] && b['DPE']['GES']
    nb.class_ges = b['DPE']['GES_letter'] if b['DPE'] && b['DPE']['GES_letter']
    
    nb.statut = 'new'
    nb.save!
	
	# If new images : Drop old images, add current images
    if b['Documents'] && b['Documents']['Document']
      pl = b['Documents']['Document']
      pl = [pl] unless pl.kind_of? Array
          nb.bien_photos.each{ |photo|
		 photo.bien = nil
		 photo.save!
          }
          # Map photo-hashes to medias, filter out failures, and add medias to good
          counter = 0
          pl.map{ |p| import_local_media(p['Filename'].to_s,(counter+=1),nb,p['Filename'].to_s) }
    end
    nb.save!

    return true

    return
  end
  
end