class InstallationsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  auto_actions_for :client, [:new, :create]
  
  web_method :data
  
  def auto_import
	begin
		puts "Start Cron Automatic Import"
		Importers.run Time.now
		puts "done."
		render :text => "Done"
	rescue	
		render :text => "Fail"
	end
  end
  
  def conversion text
	tab_conversion = {'sdl' => "<br/>",'euro' => "euros"}
	tab_conversion.each{ |elt,rpl|
		text = text.to_s.gsub(/\[#{elt}\]/,rpl)
	}
	text = text.to_s.gsub(/<br>/,"<br/>")
	return text
  end
  
  def exception_asterisque code
	not ["afimmonaco"].include? code
  end
  
  def asterisque text
	text = text.force_encoding('utf-8')
	# text = "#{text}\<br\/\>\* Prix net\, hors frais notariés\, d\'enregistrement et de publicité foncière"
	text = "#{text} \-\-\> \* Prix net, hors frais notariés, d'enregistrement et de publicité foncière"
	return text
  end

  def export_immauto_installations
	request.format = :xml
	
	root = {:installations => []}
	Installation.all.each{ |i|
		ih = {}
		ih["description"] = i.informations_supplementaires
		ih["adresse_xml_import"] = "#{$domain}/export_immauto_agence?code_installation=#{i.code_acces_distant}"
		root[:installations].push ih
	}
	
	respond_to do |format|
      format.xml  { render :xml  => root.to_xml }
    end
  end
  
  def export_firmware
	request.format = :xml
	
	if params[:instal_code].nil?
		code_err = 1
		text_err = "L'appel de ce service nécessite un instal_code"
	elsif (installation = Installation.where(:code_acces_distant => params[:instal_code]).first).nil?
		code_err = 2
		text_err = "Installation inconnue, instal_code non valide"
    elsif installation.execution_source_file.nil?
		code_err = 5
		text_err = "Pas de firmware associé à cette installation"
	else
		code_err = 0
		text_err = "ok pour #{params[:instal_code]}"
		firmware = installation.execution_source_file
	end

	root = {:firmware => {}, :result => {:err_code => code_err,:desc => text_err}}
	if code_err == 0
		root[:firmware]["md5sum"] = firmware.hashsum
		root[:firmware]["adresse_firmware"] = firmware.absolute_url
	end
	
	respond_to do |format|
      format.xml  { render :xml  => root.to_xml }
    end
  end
 
  def export_immauto_biens
    request.format = :xml
	last_update = ""
	tous_biens = []
	if params[:code_installation].nil?
		code_err = 1
		text_err = "L'appel de ce service nécessite un code_installation"
	elsif (installation = Installation.where(:code_acces_distant => params[:code_installation]).first).nil?
		code_err = 2
		text_err = "Installation inconnue, code_installation non valide"
	elsif (installation.passerelles.empty?)
		code_err = 3
		text_err = "Pas de passerelle active"
	elsif (tous_biens = installation.passerelles.map{ |p| p.biens.select{ |b| b.statut == "cur" && !b.bien_photos.empty? }}.flatten).empty?
		code_err = 4
		text_err = "Aucun biens actif et avec images"
    else
		code_err = 0
		text_err = "ok : #{tous_biens.size} actifs et avec images"
		last_update = installation.passerelles.map{ |p| p.executions.select{|e| e.statut == "ok"}.map{|e| e.updated_at}}.flatten.sort.last.strftime("%d/%m/%Y")
	end
	
	root = {:biens => [], :result => {:err_code => code_err,:desc => text_err,:last_update => last_update}}
	
	if code_err == 0		
		tous_biens.each{ |b|
			photos = b.bien_photos
			hb = b.attributes
			hb.delete "is_accueil"
			hb.delete "created_at"
			hb.delete "updated_at"
			hb.delete "passerelle_id"
			hb.delete "id"
			hb["type_categorie"] = b.bien_type.nom if b.bien_type
			hb["type_transaction"] = b.bien_transaction.nom if b.bien_transaction
			if b.bien_emplacement
				he = b.bien_emplacement.attributes
				he.delete "id"
				he.delete "created_at"
				he.delete "updated_at"
				hb["localisation"] = he
			end
			hb.delete "bien_emplacement_id"
			hb.delete "bien_type_id"
			hb.delete "bien_transaction_id"
			hb.delete "statut"
			hb["description"] = conversion(hb["description"])
			all_img = photos.map{ |p| {:url => p.absolute_url, :ordre => p.ordre}}
			hb["images"] = all_img

			root[:biens].push(hb)
		}
	end
	
	respond_to do |format|
      format.xml  { render :xml  => root.to_xml }
    end
  end
  
  def data
	request.format = :xml	
	last_update = ""
	tous_biens = []
	if params[:instal_code].nil?
		code_err = 1
		text_err = "L'appel de ce service nécessite un instal_code"
	elsif (installation = Installation.where(:code_acces_distant => params[:instal_code]).first).nil?
		code_err = 2
		text_err = "Installation inconnue, instal_code non valide"
	elsif (installation.passerelles.empty?)
		code_err = 3
		text_err = "Pas de passerelle active"
	elsif (tous_biens = installation.passerelles.map{ |p| p.biens.select{ |b| b.statut == "cur" && !b.bien_photos.empty? }}.flatten).empty?
		code_err = 4
		text_err = "Aucun bien actif et avec images"
    else
		code_err = 0
		text_err = "ok : #{tous_biens.size} actifs et avec images"
		last_update = installation.passerelles.map{ |p| p.executions.select{|e| e.statut == "ok"}.map{|e| e.updated_at}}.flatten.sort.last.strftime("%d/%m/%Y")
	end

	root = {:categories => [], :medias => [], :result => {:err_code => code_err,:desc => text_err,:last_update => last_update}}
	
	if code_err == 0
		cat_actives_id = tous_biens.map{ |b| b.bien_type_id}.compact.uniq
		transaction_actives_id = tous_biens.map{ |b| b.bien_transaction_id}.compact.uniq

		if(installation.code_acces_distant == "abcimmo")
			# special categories pour abcimmo : APPARTEMENT, MAISON, 1 pièce, 2 pièces, 3 pièces, 4 pièces et plus
			special_cat = ["APPARTEMENT","MAISON","1 pièce","2 pièces","3 pièces","4 pièces et plus"]
			special_cat.each{ |c|
				special_real_cat = BienType.find_or_create c
				root[:categories].push ({:nom => special_real_cat.nom, :id => "type-#{special_real_cat.id}"})
			}
		elsif(installation.code_acces_distant == "pige")
			special_cat = ["MAISON","TYPE 1-1BIS","TYPE 2","TYPE 3","TYPE 4-5 ET PLUS"]
			special_cat.each{ |c|
				special_real_cat = BienType.find_or_create c
				root[:categories].push ({:nom => special_real_cat.nom, :id => "type-#{special_real_cat.id}"})
			}
		elsif(cat_actives_id.size > 10 and installation.code_acces_distant != "menton")
			use_meta = true
			meta_cat_actives_id = tous_biens.select{ |b| b.bien_type}.map{ |b| b.bien_type.get_meta.id}.compact.uniq
			meta_cat_actives_id.each{ |mid|
				mc = BienType.find mid
				next if mc.nil?
				root[:categories].push ({:nom => mc.nom, :id => "type-#{mc.id}"})
			}
		else
			use_meta = false
			cat_actives_id.each{ |id|
				c = BienType.find id
				next if c.nil?
				root[:categories].push ({:nom => c.nom, :id => "type-#{c.id}"})
			}
		end
		
		transaction_actives_id.each{ |id|
			t = BienTransaction.find id
			next if t.nil?
			root[:categories].push ({:nom => t.nom, :id => "transaction-#{t.id}"})
		}
		
		# gestion des paliers de prix
		if installation.code_acces_distant != "abcimmo"
			tous_biens_ventes = tous_biens#.select{ |b| b.bien_transaction && b.bien_transaction.nom == "Vente"}
			if(tous_biens_ventes.size > 250){
				tous_biens_ventes = tous_biens_ventes[0..249]
			}
			min = 0
			if ["wayenberg","pige"].include? installation.code_acces_distant
				tous_biens_ventes = tous_biens_ventes.select{ |b| b.bien_transaction_id == 2}
				max = 900
				pas = 100
			else
				max = 225000
				pas = 25000
			end
			
			if ["littoral1","littoral2","littoralpupitre"].include? installation.code_acces_distant
				max = 7000000
				pas = 1000000
			else
				coef = 1
				increment = 1
				while((tous_biens_ventes.select{ |b| b.prix.to_i > max*coef }.size) > (tous_biens_ventes.size / 10)) do
				  coef += increment
				  increment *= 10 if coef == 10*increment
				end
				max *= coef
				pas *= coef
			end
			
			if !tous_biens_ventes.select{ |b| b.prix.to_i < pas}.empty?
				root[:categories].push ({:nom => "Moins de #{pas.humanize} €", :id => "prix-0"})
			end
			compteur = 1
			pas.step((max-pas),pas) { |i|
				if !tous_biens_ventes.select{ |b| (b.prix.to_i >= i) && (b.prix.to_i < (pas+i))}.empty?
					root[:categories].push ({:nom => "Entre #{i.humanize} € et #{(pas+i).humanize} €", :id => "prix-#{compteur}"})
				end
				compteur += 1
			}
			if !tous_biens_ventes.select{ |b| b.prix.to_i >= max}.empty?
				root[:categories].push ({:nom => "Plus de #{max.humanize} €", :id => "prix-#{compteur}"})
			end
		end
		
		compteur_dpe_img = 0
		compteur_img = 0
		# attrs_img_autre = {:titre => "", :url => "", :ordre => ""}
		# attrs_img_principal = {:titre => "", :url => ""}
		tous_biens.each{ |b|
			next if b.bien_transaction.nil?
			compteur_dpe_img += 1
			photos = b.bien_photos
			first = photos.first
			others = photos - [first]
			if b.prix && b.prix > 0
				if b.bien_transaction.nom.to_s.downcase == "location"
					titre1 = "#{b.prix.humanize} € C.C."
				else
					if (["littoral1","littoral2","littoralpupitre"].include? installation.code_acces_distant) && (b.prix > 7000000)
						titre1 = "Prix : Nous consulter"
					elsif exception_asterisque params[:instal_code]
						titre1 = "#{b.prix.humanize} €*"
					else
						titre1 = "#{b.prix.humanize} €"
					end
				end
			else
				titre1 = "Prix non renseigné"
			end
			titre1 = "#{b.bien_emplacement.ville.force_encoding('utf-8')} - #{titre1}" if b.bien_emplacement && b.bien_emplacement.ville && (not b.bien_emplacement.ville.empty?)
			next if photos.empty?
			titre2 = "#{b.reference}"
			titre2 = "#{b.titre} - #{titre2}" if b.titre && (not b.titre.empty?)
			media_accueil = b.is_accueil
			media_accueil = true if b.passerelle.tous_accueil
			media_text = b.custom_description
			media_text = conversion(media_text)
			media_text = asterisque(media_text) if ((exception_asterisque params[:instal_code]) && (b.bien_transaction.nom.to_s.downcase == "vente"))
			all_img = others.map{ |p| {:titre => "img_#{(compteur_img +=1)}.jpg", :url => p.absolute_url, :ordre => p.ordre}}
			if b.classe_ges
				all_img = [{:titre => "ges_schema_#{b.classe_ges}_#{compteur_dpe_img}.jpg", :url => "#{$domain}/images/dpe_schema/ges_schema_#{b.classe_ges}.JPG", :ordre => 0}]+all_img
			end
			if b.classe_energie
				all_img = [{:titre => "dpe_schema_#{b.classe_energie}_#{compteur_dpe_img}.jpg", :url => "#{$domain}/images/dpe_schema/dpe_schema_#{b.classe_energie}.JPG", :ordre => 0}]+all_img
			end
			cats = []
			cats.push ({:id => "transaction-#{b.bien_transaction.id}"}) if b.bien_transaction
			if(installation.code_acces_distant == "abcimmo")
				# special categories pour abcimmo : APPARTEMENT, MAISON, 1 pièce, 2 pièces, 3 pièces, 4 pièces et plus
				if b.nb_piece && b.nb_piece > 0
					if b.nb_piece == 1
						special_real_cat = BienType.find_or_create "1 pièce"
					elsif b.nb_piece == 2
						special_real_cat = BienType.find_or_create "2 pièces"
					elsif b.nb_piece == 3
						special_real_cat = BienType.find_or_create "3 pièces"
					else
						special_real_cat = BienType.find_or_create "4 pièces et plus"
					end
					cats.push ({:id => "type-#{special_real_cat.id}"})
				else
					next
				end
				if b.bien_type
					if b.bien_type.nom.to_s.downcase == "appartement"
						special_real_cat = BienType.find_or_create "APPARTEMENT"
					elsif b.bien_type.nom.to_s.downcase == "maison"
						special_real_cat = BienType.find_or_create "MAISON"
					else
						next
					end
					cats.push ({:id => "type-#{special_real_cat.id}"})
				end
			elsif(installation.code_acces_distant == "pige")
				if b.bien_type
					if b.bien_type.nom.to_s.downcase == "appartement"
						if b.nb_piece && b.nb_piece > 0
							if b.nb_piece == 1
								special_real_cat = BienType.find_or_create "TYPE 1-1BIS"
							elsif b.nb_piece == 2
								special_real_cat = BienType.find_or_create "TYPE 2"
							elsif b.nb_piece == 3
								special_real_cat = BienType.find_or_create "TYPE 3"
							else
								special_real_cat = BienType.find_or_create "TYPE 4-5 ET PLUS"
							end
						else
							next
						end
					elsif b.bien_type.nom.to_s.downcase == "maison"
						special_real_cat = BienType.find_or_create "MAISON"
					else
						next
					end
					cats.push ({:id => "type-#{special_real_cat.id}"})
				end
			elsif use_meta
				cats.push ({:id => "type-#{b.bien_type.get_meta.id}"}) if b.bien_type
			else
				cats.push ({:id => "type-#{b.bien_type.id}"}) if b.bien_type
			end
			if(b.prix && (installation.code_acces_distant != "abcimmo"))
				if b.prix/pas >= 9
					cats.push ({:id => "prix-9"})
				else
					cats.push ({:id => "prix-#{b.prix/pas}"})
				end
			end
			root[:medias].push({:titre => titre1, :titre2 => titre2, :text => media_text, :accueil => media_accueil,
			:img_principal => ({:titre => "img_#{(compteur_img +=1)}.jpg", :url => first.absolute_url}),
			:img_autres => all_img,
			:categories => cats})
		}
		
	end
	
    respond_to do |format|
      format.xml  { render :xml  => root.to_xml }
    end
  end
  
end
