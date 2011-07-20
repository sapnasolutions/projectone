class InstallationsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  auto_actions_for :client, [:new, :create]
  
  # hash :
  # {
  # :categories => [{:categorie => {attrs_cat}},{:categorie => {attrs_cat}},{:categorie => {attrs_cat}}]
  # :medias => [{:media => {attrs_med}},{:media => {attrs_med}},{:media => {attrs_med}}]
  # }
  # attrs_med = {:titre => "", :titre2 => "", :text => "", :img_principal => {attrs_img_principal},
  #  	:img_autres => [{:img_autre => {attrs_img_autre}},{:img_autre => {attrs_img_autre}},{:img_autre => {attrs_img_autre}}]
  #		:categories => [{:id => 1},{:id => 2},{:id => 3}]}
  
  # attrs_cat = {:nom => "", :id => ""}
  
  # attrs_img_autre = {:titre => "", :url => "", :ordre => ""}
  # attrs_img_principal = {:titre => "", :url => "", :ordre => ""}
  
  #les catégories : type de transaction actives, type de biens actif, tri par budget malin 5 paliés.
  
  def export
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

	root = {:categories => [], :medias => [], :result => {:err_code => code_err,:desc => text_err}}
	
	if code_err == 0
		tous_biens = installation.passerelles.map{ |p| p.biens }.flatten
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

		# attrs_img_autre = {:titre => "", :url => "", :ordre => ""}
		# attrs_img_principal = {:titre => "", :url => ""}
		tous_biens.each{ |b|
			photos = b.bien_photos
			first = photos.first
			others = photos - [first]
			next if photos.empty?
			titre2 = nil
			titre2 = b.bien_emplacement.ville if b.bien_emplacement
			cats = []
			cats.push ({:id => "transaction-#{b.bien_transaction.id}"}) if b.bien_transaction
			cats.push ({:id => "type-#{b.bien_type.id}"}) if b.bien_type
			root[:medias].push({:titre => b.titre, :titre2 => titre2, :text => b.description,
			:img_principal => ({:titre => first.titre, :url => first.absolute_url}),
			:img_autres => others.map{ |p| {:titre => p.titre, :url => p.absolute_url, :ordre => p.ordre}},
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
