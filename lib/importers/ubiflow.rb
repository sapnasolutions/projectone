class Importers::Ubiflow < Importers::FromFiles
  
  # un fichier zip est un fichier binaire :)
  def initialize passerelle
    super passerelle, %w(application/zip)
  end
  
  #waiting parameters : code_agence
  #login : rault
  #pass : ar4hf4UdIl
  UBI_FTP_FOLDER = "ubiflow/"
  
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
        return unless ExecutionSourceFile.where(:hashsum => (Digest::MD5.hexdigest tmp_file.read)).select{ |e| e.execution && e.execution.passerelle == @passerelle }.empty? && filename =~ /#{@parameters["code_agence"]}.zip/
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
  
  CAT_CODE_MATCHING = {"0" =>  "Bien immobilier", "1000" => "Bien habitation (particuliers)",  "1100" => "Appartement", "1111" => "Appartement ancien", "1112" => "Appartement bourgeois", "1113" => "Appartement \� r\�nover", "1114" => "Appartement r\�nov\�", "1115" => "Appartement r\�cent", "1116" => "Appartement neuf", "1131" => "Chambre", "1132" => "Studio", "1133" => "T1", "1134" => "T1 bis", "1135" => "T2", "1136" => "T3", "1137" => "T4", "1138" => "T5", "1139" => "T6 et plus", "1180" => "Habitation de loisirs", "1190" => "Autre", "1191" => "Loft", "1192" => "Duplex\/Triplex", "1193" => "Meubl\�", "1200" => "Maison", "1210" => "Maison individuelle", "1211" => "Maison neuve", "1212" => "Pavillon", "1213" => "Villa", "1214" => "Maison de village", "1215" => "Maison de ville", "1216" => "Mas", "1217" => "Mazet", "1218" => "Ch\�let", "1219" => "Maison en bois", "1220" => "Moulin", "1221" => "Maison de rapport", "1222" => "Maison ancienne", "1223" => "Maison traditionnelle", "1224" => "Maison d'architecte", "1225" => "Maison de bourg", "1226" => "Maison en pierres", "1227" => "Maison \� r\�nover", "1228" => "Echoppe bordelaise", "1240" => "Propri\�t\�", "1241" => "Ch\�teau", "1242" => "H\�tel particulier", "1243" => "Manoir", "1244" => "Maison de ma\�tres", "1245" => "Demeure ancienne", "1246" => "Demeure traditionnelle", "1247" => "Demeure contemporaine", "1248" => "Demeure", "1260" => "Maison situ\�e en campagne", "1261" => "Maison de campagne", "1262" => "Fermette", "1263" => "Ferme", "1264" => "Long\�re", "1265" => "Remise", "1266" => "Grange", "1267" => "Corps de ferme", "1280" => "Habitation de loisirs", "1281" => "Bungalow", "1282" => "G\�te", "1283" => "Chambre d'h\�tes", "1284" => "Mobil-home", "1290" => "Divers maison", "1300" => "Terrain", "1310" => "Terrain \� b\�tir", "1320" => "ZI\/ZAC", "1330" => "Lotissement", "1340" => "Programme terrain+maison", "1350" => "Terrain \� am\�nager", "1351" => "Jardin", "1352" => "Terrain de loisirs", "1360" => "Terrain agricole", "1370" => "Ile", "1390" => "Divers terrains", "1391" => "For\�t", "1400" => "Stationnement", "1410" => "Parking", "1411" => "Parking couvert", "1412" => "Parking externe", "1420" => "Garage\/box", "1421" => "Garage individuel", "1422" => "Place de garage", "1500" => "Immeuble", "1900D" => "Divers", "1901" => "Cave", "1902" => "Grenier", "1903" => "Cabanon", "1904" => "Caveau\/Concession", "1905" => "Hangar", "2000" => "Bien d'entreprise ou commerce (professionnels)", "2100" => "Industrie\/Production", "2110" => "Agriculture\/Viticulture", "2130" => "Agroalimentaire", "2140" => "BTP", "2150" => "Charpente\/Menuiserie\/Couverture", "2160" => "M\�canique\/M\�tallurgie", "2190" => "Divers industrie", "2200" => "Services", "2201" => "Garage\/Station service", "2202" => "Nettoyage\/Pressing\/Teinturerie", "2203" => "Conseil", "2204" => "D\�pannage\/R\�paration", "2205" => "Electricit\�\/Electronique", "2206" => "Professions immobili\�res", "2207" => "Loisirs\/Tourisme", "2208" => "Plomberie", "2209" => "Professions lib\�rales", "2210" => "Prestations multimedia", "2211" => "Publicit\�", "2212" => "Sant\�", "2213" => "Transports\/Taxi", "2214" => "Vid\�o\/Photo", "2215" => "Carrelage\/Ma\�onnerie", "2216" => "Peinture\/Vitrerie\/Pl\�trerie", "2217" => "Serrurerie\/M\�tallerie", "2290" => "Divers services" ,"2291" => "Multiservices" ,"2300" => "Commerces\/Negoce" ,"2310" => "Caf\�\/H\�tel\/Restaurant", "2311" => "Bar\/Brasserie\/Tabac", "2321" => "H\�tel", "2312" => "H\�tel Restaurant", "2313" => "Restaurant", "2314" => "Cr\�perie\/Pizzeria", "2315" => "Restauration rapide", "2316" => "Salon de th\�", "2317" => "Sandwicherie", "2318" => "Camping", "2319" => "Club\/Discoth\�que", "2320" => "Glacier", "2330" => "Commerce alimentaire", "2331" => "Boucherie\/Charcuterie", "2332" => "Poissonnerie", "2333" => "Alimentation", "2334" => "Boulangerie\/P\�tisserie", "2335" => "Traiteur", "2336" => "Cr\�merie\/Fromagerie", "2340" => "Equipement de la personne", "2341" => "Bijouterie\/Horlogerie", "2342" => "Chaussure\/Cuir", "2343" => "Habillement\/Textile", "2350" => "Parfumerie\/Coiffure\/Cadeaux\/Fleurs", "2351" => "Cadeaux\/Fleurs", "2352" => "Beaut\�\/Esth\�tique\/Coiffure", "2360" => "Librairie\/Papeterie\/Tabac\/Presse", "2361" => "Librairie\/Papeterie", "2362" => "Tabac\/Presse", "2370" => "Equipement de la maison", "2371" => "HiFi\/Electrom\�nager", "2372" => "Informatique\/Multimedia", "2373" => "Mobilier\/D\�coration", "2374" => "Art de la table", "2380" => "Autos\/Motos\/Scooters\/Cycles", "2381" => "Autos", "2382" => "Motos\/Scooters", "2383" => "Cycles", "2390" => "Divers commerces", "2391" => "Pharmacie", "2392" => "Animalerie\/Chasse\/P\�che", "2393" => "Cave \� vins", "2400" => "Locaux\/Biens immobiliers", "2410" => "Bureau", "2420" => "Local d'activit\�", "2421" => "Local artisanal", "2422" => "Local industriel\/Entrep\�t", "2423" => "Loft\/Atelier", "2430" => "Boutique", "2490" => "Divers immobilier d'entreprise", "2491" => "B\�timent", "2492" => "Centre d'affaires", "2493" => "Plateau", "2900" => "Divers professionnel", "3000" => "Programme neuf", "3100" => "Programme de maisons", "3200" => "Programme d'appartements", "3300" => "Programme de terrains", "4000" => "Lot neuf type", "4100" => "Lot de maisons", "4200" => "Lot d'appartements", "4300" => "Lot de terrains"}
  
  # Create a new good, and return the ActiveRecord
  def import_bien b

    # Good location
    good_address = {}
    loc = BienEmplacement.new
	loc.pays = "France"
	loc.code_postal = b["bien"]["code_postal"]
	loc.ville = b["bien"]["ville"]

	ref = b["reference"]
	
	cat_code = b["bien"]["code_type"].to_s
	cat_s = CAT_CODE_MATCHING[cat_code]
	
	cat = BienType.find_or_create cat_s.up_first

	# Determine if the good is a sell or a rent
	price = b["prestation"]["prix"].to_i
    if b["prestation"]["type"] == "V"
      transaction_type = BienTransaction.where(:nom => 'Vente').first
    elsif b["prestation"]["type"] == "L"
	  transaction_type = BienTransaction.where(:nom => 'Location').first
    else
		Logger.send("warn","Type de transaction inconnue : #{b["prestation"]["type"]} pour le bien ref : #{ref}")
		@result[:description] << "Type de transaction inconnue : #{b["prestation"]["type"]} pour le bien ref : #{ref}"
        return false
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
	
	nb.statut = 'new'
    nb.save!
	
	if b["bien"]["diagnostiques"]
		nb.valeur_dpe = b["bien"]["diagnostiques"]["dpe_valeur_conso"]
		nb.classe_dpe = b["bien"]["diagnostiques"]["dpe_etiquette_conso"]
	
		nb.valeur_ges = b["bien"]["diagnostiques"]["dpe_valeur_ges"]
		nb.class_ges = b["bien"]["diagnostiques"]["dpe_etiquette_ges"]
	end
	
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
      pl.map { |p| import_remote_media(p.to_s,(counter+=1),nb) }
    end
	
    nb.save!

    return
	end
	
  end