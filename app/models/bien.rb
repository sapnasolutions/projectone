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
  
  # def custom_description
	# return DefaultCustomDescription.map{ |key,value|
		# next if self.attributes[key].nil? || self.attributes[key].to_s.empty?
		# if value
			# self.stringed_attr key
		# else
			# self.attributes[key].to_s
		# end
	# }.select{|s| !(s.nil? || s.empty?)}.join("\n")
  # end
  
  def custom_description
	begin
		begin
			desc = HTMLEntities.new.decode(self.description)
		rescue
			desc = self.description
		end
		desc = desc.gsub(/<br>/,"")
		desc = desc.gsub(/<\/br>/,"")
		desc = desc.gsub(/<br\/>/,"")
		desc = desc.gsub(/<br \/>/,"")
		desc = desc.gsub(/<p>/,"")
		desc = desc.gsub(/<\/p>/,"")
	rescue
		desc = self.description
	end
	return desc
  end
  
  def classe_energie
	return self.classe_dpe if self.classe_dpe
	return nil if self.valeur_dpe.nil? || self.valeur_dpe == 0
	case self.valeur_dpe
	  when 1..50 then
		return 'A'
	  when 51..90 then
		return 'B'
	  when 91..150 then
		return 'C'
	  when 151..230 then
		return 'D'
	  when 231..330 then
		return 'E'
	  when 331..450 then
		return 'F'
	  else
		return 'G'
	end    
  end
  
  def classe_ges
	return self.class_ges if self.class_ges
	return nil if self.valeur_ges.nil? || self.valeur_ges == 0
	case self.valeur_ges
	  when 1..5 then
		return 'A'
	  when 6..10 then
		return 'B'
	  when 11..20 then
		return 'C'
	  when 21..35 then
		return 'D'
	  when 36..55 then
		return 'E'
	  when 56..80 then
		return 'F'
	  else
		return 'G'
	end    
  end
  
  def save
	self.valeur_ges = nil if self.valeur_ges == 0
    self.class_ges = nil unless self.class_ges != "" && self.class_ges =~ /^[A-Ga-g]$/
	
	self.valeur_dpe = nil if self.valeur_dpe == 0
    self.classe_dpe = nil unless self.classe_dpe != "" && self.classe_dpe =~ /^[A-Ga-g]$/
	super
  end
  
  def save!
	self.valeur_ges = nil if self.valeur_ges == 0
    self.class_ges = nil unless self.class_ges != "" && self.class_ges =~ /^[A-Ga-g]$/
	
	self.valeur_dpe = nil if self.valeur_dpe == 0
    self.classe_dpe = nil unless self.classe_dpe != "" && self.classe_dpe =~ /^[A-Ga-g]$/
	super
  end

end
