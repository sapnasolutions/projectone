class InstallationsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  auto_actions_for :client, [:new, :create]
  
  web_method :data
  
  def data
	request.format = :xml
	
    if params[:instal_code].nil?
		code_err = 1
		text_err = "need a value in params instal_code"
	elsif (installation = Installation.where(:code_acces_distant => params[:instal_code]).first).nil?
		code_err = 2
		text_err = "Installation Uknown"
    else
		code_err = 0
		text_err = "ok"
	end

	last_update = installation.passerelles.map{ |p| p.executions.select{|e| e.statut == "ok"}.map{|e| e.updated_at}}.flatten.sort.last.strftime("%d/%m/%Y")
	root = {:categories => [], :medias => [], :result => {:err_code => code_err,:desc => text_err,:last_update => last_update}}
	
	if code_err == 0
		tous_biens = installation.passerelles.map{ |p| p.biens.select{ |b| b.statut == "cur" && !b.bien_photos.empty? }}.flatten
		cat_actives_id = tous_biens.map{ |b| b.bien_type_id}.compact.uniq
		transaction_actives_id = tous_biens.map{ |b| b.bien_transaction_id}.compact.uniq

		cat_actives_id.each{ |id|
			c = BienType.find id
			next if c.nil?
			root[:categories].push ({:nom => c.nom, :id => "type-#{c.id}"})
		}
		transaction_actives_id.each{ |id|
			t = BienTransaction.find id
			next if t.nil?
			root[:categories].push ({:nom => t.nom, :id => "transaction-#{t.id}"})
		}
		
		# gestion des paliers de prix
		tous_biens_ventes = tous_biens#.select{ |b| b.bien_transaction && b.bien_transaction.nom == "Vente"}
		min = 0
        max = 225000
        pas = 25000 
		coef = 1
        increment = 1
        while((tous_biens_ventes.select{ |b| b.prix > max*coef }.size) > (tous_biens_ventes.size / 10)) do
          coef += increment
          increment *= 10 if coef == 10*increment
        end
        max *= coef
        pas *= coef
		if !tous_biens_ventes.select{ |b| b.prix < pas}.empty?
			root[:categories].push ({:nom => "Moins de #{pas.to_s} \€", :id => "prix-0"})
		end
		compteur = 1
		pas.step((max-pas),pas) { |i|
			if !tous_biens_ventes.select{ |b| (b.prix >= i) && (b.prix < (pas+i))}.empty?
				root[:categories].push ({:nom => "Entre de #{i.to_s} \€ et #{pas+i} \€", :id => "prix-#{compteur}"})
			end
			compteur += 1
		}
		if !tous_biens_ventes.select{ |b| b.prix >= max}.empty?
			root[:categories].push ({:nom => "Plus de #{max.to_s} \€", :id => "prix-#{compteur}"})
		end
		
		compteur_dpe_img = 0
		# attrs_img_autre = {:titre => "", :url => "", :ordre => ""}
		# attrs_img_principal = {:titre => "", :url => ""}
		tous_biens.each{ |b|
			compteur_dpe_img += 1
			photos = b.bien_photos
			first = photos.first
			others = photos - [first]
			titre1 = "#{b.prix.to_s} \€ F.A.I."
			titre1 = "#{b.bien_emplacement.ville} - #{titre1}" if b.bien_emplacement
			next if photos.empty?
			titre2 = "#{b.titre} - #{b.reference}"
			media_accueil = b.is_accueil
			media_text = b.custom_description
			all_img = others.map{ |p| {:titre => p.titre, :url => p.absolute_url, :ordre => p.ordre}}
			if b.classe_ges
				all_img = [{:titre => "dpe-schema-#{b.classe_ges}-#{compteur_dpe_img}", :url => "#{$domain}/images/dpe_schema/ges_schema_#{b.classe_ges}.JPG", :ordre => 0}]+all_img
			end
			if b.classe_energie
				all_img = [{:titre => "dpe-schema-#{b.classe_energie}-#{compteur_dpe_img}", :url => "#{$domain}/images/dpe_schema/dpe_schema_#{b.classe_energie}.JPG", :ordre => 0}]+all_img
			end
			cats = []
			cats.push ({:id => "transaction-#{b.bien_transaction.id}"}) if b.bien_transaction
			cats.push ({:id => "type-#{b.bien_type.id}"}) if b.bien_type
			if b.prix
				if b.prix/pas >= 9
					cats.push ({:id => "prix-9"})
				else
					cats.push ({:id => "prix-#{b.prix/pas}"})
				end
			end
			root[:medias].push({:titre => titre1, :titre2 => titre2, :text => media_text, :accueil => media_accueil,
			:img_principal => ({:titre => first.titre, :url => first.absolute_url}),
			:img_autres => all_img,
			:categories => cats})
		}
		
		# snippet for generate "paliers" of price (create cat)
		# if type == "vente"
		  # min = 0
		  # max = 225000
		  # pas = 25000         
		# else
		  # min = 0
		  # max = 500
		  # pas = 50
		# end
		
		# coef = 1
		# increment = 1
		# while((goods.select{ |g| g.price > max*coef }.size) > (goods.size / 10)) do
		  # coef += increment
		  # increment *= 10 if coef == 10*increment
		# end
		# max *= coef
		# pas *= coef
		# min.step(max,pas) { |i|
			# newPalier = Hash.new
			# newPalier['indice'] = i
			
			# if typePalier == "rooms"
			  # newPalier['txt'] = signe+"pièce".count_enum(i)
			# else
			  # newPalier['txt'] = signe+i.humanize+" "+paliers["unite"]
			# end
					
			# if ordre.nil? || ordre == "ASC"
			  # newPalier['goods'] = goods.select{ |good|  good[typePalier] >= i && good[typePalier] < i + pas }
			# else
			  # newPalier['goods'] = goods.select{ |good|  good[typePalier] < i && good[typePalier] >= i + pas }
			# end
			# paliers["paliers"].push newPalier
		# }
	end
	
    respond_to do |format|
      format.xml  { render :xml  => root.to_xml }
    end
  end
  
end
