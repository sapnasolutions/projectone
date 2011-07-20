class Importers::Pericles < Importers::FromFtp
  
  FTP_ADRESS = "ftp.hilabs.net"
  FTP_MEDIA_REPO = "/"
  FTP_FILE_REPO = "/"
  
  ######## to delete; only for test
  def import
  #  scan_files
    # import non-imported files
	Execution.where(:passerelle_id => @passerelle.id, :statut => "nex").order_by(:created_at).each{ |execution|
		result = import_exe execution
		# if result
			# execution.statut = "ok"
		# else
			# execution.statut = "err"
		# end
		# execution.save!
	}
    @passerelle.updated_at = DateTime.now
    @passerelle.save!
  end
  
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(application/zip), "zip", FTP_ADRESS, FTP_FILE_REPO, FTP_MEDIA_REPO
  end
  
  def import_exe execution
	Logger.send("warn","[Pericles] Starting PERICLES execution import")

    z = Zip::ZipFile.open(execution.execution_source_file.file.path)

    dl_and_update_medias z

    z.each do |entry|
      next unless (entry.name.downcase =~ /.xml$/ || entry.name.downcase =~ /.txt$/)
      data = z.read(entry)
      if entry.name.downcase =~ /.xml$/
        tree = Hash.from_xml(data)
        @dataType = "xml"
      else
        tree = hash_from_txt(data)
        @dataType = "txt"
      end
      @mapTable = Hash.new
	  import_hash(tree)
    end

    count_media_update = matching_import_image
	Logger.send("warn","Updated the media of #{count_media_update} good")
    
    z.close

    update_goods    
    
	Logger.send("warn","Finished PERICLES zipfile import")
    return
  end
  
    # return the good associated at the media name
  def match_agency_ref_by_name name
    if @dataType.to_s == "xml"
      return nil unless name =~ /([0-9]+-[0-9]+)-([0-9]+)-/
      #agency_source_key = "#{@passerelle.id}-#{$1.to_s.downcase}"
      agency_code = $2.to_s.downcase
    elsif @dataType.to_s == "txt"
      return nil unless name =~ /(.[0-9]{2})([0-9]+)/
      source_key =( @agencyName+"-"+$1).to_s.downcase
      agency_code = ("V"+$1+$2).to_s.downcase
    else
	  Logger.send("warn","dataType non Connu : [#{@dataType.to_s}]")
      return nil
    end
    
    agency_ref = @mapTable[agency_code]
    agency_ref = agency_code if agency_ref.nil?
    
    return agency_ref    
  end
  
   # Import a hash in Pericles tree format.
  # Return the list of agencies in the tree.
  def import_hash hashtree
	Logger.send("warn","Start XML(hash) import")

    # Create and list new goods
    hashtree["BIENS"]["BIEN"].each { |b|
      next if (b.class.name != "Hash" || b["CODE_SOCIETE"].nil? || b["CODE_SITE"].nil?)
      import_bien b
    }
	
	Logger.send("warn","End XML import")
    return true
  end
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	if b["VILLE_INTERNET"]
		loc.code_postal = b["CP_INTERNET"]	
		loc.ville = b["VILLE_INTERNET"]
	else
		loc.code_postal = b["CP_OFFRE"]	
		loc.ville = b["VILLE_OFFRE"]
	end	

	# Determine if the good is a sell or a rent
	# We have to check the field "prix" or the field "loyer"
    unless b["PRIX"].nil? || b["PRIX"].to_s.empty? || b["PRIX"].to_i == 0
      price = b["PRIX"].to_i
      transaction_type = BienTransaction.where(:nom => 'Vente').first
    else 
      unless b["LOYER"].nil? || b["LOYER"].to_s.empty?  || b["LOYER"].to_i == 0
        price = b["LOYER"].to_i
		transaction_type = BienTransaction.where(:nom => 'Location').first
      else
		Logger.send("warn","Prix vente | location null pour le bien ref : #{b["NO_ASP"]}")
        return false
      end
    end

    
    if b["NO_MANDAT"] && !b["NO_MANDAT"].to_s.empty?
		ref = b["NO_MANDAT"].to_s.downcase
	else
		ref = b["NO_ASP"].to_s.downcase
	end
    @mapTable[b["NO_ASP"].to_s.downcase] = ref
    
	nb = Bien.where(:reference => ref).first
    nb = Bien.new if nb.nil?

	cat = BienType.where(:nom => b["CATEGORIE"]).first
	if cat.nil?
		cat = BienType.new(:nom => b["CATEGORIE"])
		cat.save!
	end
    b["SURF_HAB"] ||= b["SURF_CARREZ"]
	
	desc = b["TEXTE_FR"]
    desc = b["TEXTE_MAILING"] if b["TEXTE_MAILING"] && !b["TEXTE_MAILING"].to_s.empty?

    nb.passerelle = @passerelle
    nb.reference = ref
    nb.bien_type = cat
    nb.bien_transaction = transaction_type
    nb.bien_emplacement = loc
    nb.nb_piece = b["NB_PIECES"]
    nb.nb_chambre = b["NB_CHAMBRES"]
    nb.surface = b["SURF_HAB"]
    nb.surface_terrain = b["SURF_TERRAIN"]
    nb.titre = b["CATEGORIE"]
    nb.prix = price
    nb.description = desc
    nb.valeur_dpe = b["DPE_VAL1"]
    nb.statut = 'new'
    nb.save!

    return
  end
  
  # return the hash calculated from a pericles txt file
  def hash_from_txt(data)
      strGoods = data.split(',"FIN"')
      hashTree = Hash.new
      hashTree["BIENS"] = Hash.new
      hashTree["BIENS"]["BIEN"] = Array.new
      @agencyName = ""
      strGoods.each { |strGood|
          strGoodClean = strGood[1..(strGood.size-2)]
          strGoodAttrs = strGoodClean.split('","')
          push = false
          if strGoodAttrs.size == 91
            goodTree = Hash.new
            goodTree["NO_ASP"] = strGoodAttrs[1]
            goodTree["CODE_SITE"] = strGoodAttrs[2]
            goodTree["PRIX"] = strGoodAttrs[5]
            goodTree["VILLE_OFFRE"] = strGoodAttrs[27]
            goodTree["CATEGORIE"] = Iconv.conv('utf-8','cp1252',strGoodAttrs[29].to_s)
            goodTree["NB_PIECES"] = strGoodAttrs[30]
            goodTree["NB_CHAMBRES"] = strGoodAttrs[31]
            goodTree["SURF_HAB"] = strGoodAttrs[32]
            goodTree["SURF_TERRAIN"] = strGoodAttrs[35]
          
            utf8str = Iconv.conv('utf-8','cp1252',strGoodAttrs[61])
            goodTree["TEXTE_FR"] = utf8str
            strGoodAttrs[62..72].each { |strDescr|
              utf8str = Iconv.conv('utf-8','cp1252',strDescr)
              goodTree["TEXTE_FR"] += " "+utf8str unless (strDescr.nil? or strDescr == "")
            }
          
            goodTree["RS_AGENCE"] = strGoodAttrs[83]
            goodTree["CODE_SOCIETE"] = strGoodAttrs[83]
            goodTree["ADRESSE1_AGENCE"] = strGoodAttrs[84]
            goodTree["ADRESSE2_AGENCE"] = strGoodAttrs[85]
            goodTree["CP_AGENCE"] = strGoodAttrs[86]
            goodTree["VILLE_AGENCE"] = strGoodAttrs[87]
            goodTree["TEL_AGENCE"] = strGoodAttrs[88]
            goodTree["MAIL_AGENCE"] = strGoodAttrs[90]
            @agencyName = goodTree["RS_AGENCE"]
            push = true;
          elsif strGoodAttrs.size == 112
            goodTree = Hash.new
            goodTree["NO_ASP"] = strGoodAttrs[1]
            goodTree["CODE_SITE"] = strGoodAttrs[2]
            goodTree["PRIX"] = strGoodAttrs[5]
            goodTree["VILLE_OFFRE"] = strGoodAttrs[36]
            goodTree["VILLE_INTERNET"] = strGoodAttrs[37]
            goodTree["CATEGORIE"] = Iconv.conv('utf-8','cp1252',strGoodAttrs[38].to_s)
            goodTree["NB_PIECES"] = strGoodAttrs[39]
            goodTree["NB_CHAMBRES"] = strGoodAttrs[40]
            goodTree["SURF_HAB"] = strGoodAttrs[41]
            goodTree["SURF_TERRAIN"] = strGoodAttrs[44]
          
            utf8str = Iconv.conv('utf-8','cp1252',strGoodAttrs[76])
            goodTree["TEXTE_FR"] = utf8str
            strGoodAttrs[77..81].each { |strDescr|
              utf8str = Iconv.conv('utf-8','cp1252',strDescr)
              goodTree["TEXTE_FR"] += " "+utf8str unless (strDescr.nil? or strDescr == "")
            }
          
            goodTree["RS_AGENCE"] = strGoodAttrs[104]
            goodTree["CODE_SOCIETE"] = strGoodAttrs[104]
            goodTree["ADRESSE1_AGENCE"] = strGoodAttrs[105]
            goodTree["ADRESSE2_AGENCE"] = strGoodAttrs[106]
            goodTree["CP_AGENCE"] = strGoodAttrs[107]
            goodTree["VILLE_AGENCE"] = strGoodAttrs[108]
            goodTree["TEL_AGENCE"] = strGoodAttrs[109]
            goodTree["MAIL_AGENCE"] = strGoodAttrs[111]
            @agencyName = goodTree["RS_AGENCE"]
            push = true;
          else
			Logger.send("warn","Nombre de champs non conformes : nb : #{(strGoodAttrs.size).to_s}")
          end
          hashTree["BIENS"]["BIEN"].push(goodTree) if push
      }
      return hashTree
  end
end