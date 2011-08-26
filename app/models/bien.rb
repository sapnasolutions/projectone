class Bien < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    nb_piece           :integer
    prix               :integer
    surface            :integer
    surface_terrain    :integer
    titre              :string
    description        :text
    date_disponibilite :date
    statut             :string
    nb_chambre         :integer
    valeur_dpe         :integer
    valeur_ges         :integer
    classe_dpe         :string
    class_ges          :string
    reference          :string
    timestamps
  end

  belongs_to :bien_emplacement#, :as => :emplacement
  belongs_to :bien_transaction#, :as => :transaction
  belongs_to :bien_type#, :as => :type
  belongs_to :passerelle
  has_many :bien_photos, :dependent => :destroy
  
  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end
  
  ListeAttrPossible = {
	# "id" => 5,
	# "bien_emplacement_id" => nil, 
	# "bien_transaction_id" => nil,
	# "bien_type_id" => nil,
	# "created_at" => "",
	# "passerelle_id" => 4,
	# "statut"=>"",
	# "updated_at" => "",
	
	"class_ges" => "Classe émission de GES",
	"classe_dpe" => "Classe énergie",
	"date_disponibilite" => "Disponible le",
	"description" => "Description",
	"nb_chambre" => "Nombre de chambres",
	"nb_piece" => "Nombre de pièces",
	"prix" => "Prix",
	"reference" => "Référence",
	"surface" => "Surface",
	"surface_terrain" => "Surface Terrain",
	"titre" => "Titre",
	"valeur_dpe" => "Valeur énergie",
	"valeur_ges" => "Valeur émission de GES"
  }
  
  DefaultCustomDescription = {
	"description" => false,
	"classe_dpe" => true,
	"valeur_dpe" => true,
	"nb_piece" => true,
	"nb_chambre" => true,
	"surface" => true,
	"surface_terrain" => true
  }
  
  def stringed_attr attr
	return "#{ListeAttrPossible[attr]} : #{self.attributes[attr]}"
  end
  
  def custom_description
	return DefaultCustomDescription.map{ |key,value|
		next if self.attributes[key].nil? || self.attributes[key].to_s.empty?
		if value
			self.stringed_attr key
		else
			self.attributes[key].to_s
		end
	}.select{|s| !(s.nil? || s.empty?)}.join("\n")
  end

end
