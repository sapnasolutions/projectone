class BienType < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    nom :string
    timestamps
  end
  
  has_many :biens, :dependent => :nullify
  
  def self.find_or_create nom
    return nil if nom.nil? || nom.empty?
	return BienType.where(:nom => nom).first unless BienType.where(:nom => nom).empty?	
	return BienType.where(:nom => nom).first if BienType.new(:nom => nom).save
	return nil
  end
  
  def self.metas
	return [(BienType.find_or_create "Maisons"),(BienType.find_or_create "Appartements"),(BienType.find_or_create "Commerces et Locaux commerciaux"),(BienType.find_or_create "Parkings et Garages"),(BienType.find_or_create "Batiments"),(BienType.find_or_create "Autre")]
  end
  
  def get_meta
	case self.nom.to_s.pretty_sms.downcase
        when /propriete|maison|villa|ferme|chalet|pavillon|amien|demeure|manoir|chateau|batisse|angevine|mancelle|contemporaine|toulousaine|manoir|bastide|pied|prestig/ then
          # Maison
          return BienType.find_or_create "Maisons"
        when /appart|loft|t[ ]{0,1}[0-9]|f[ ]{0,1}[0-9]|studio|duplex|triplex|rez|chambre/ then
          # Appartement
          return BienType.find_or_create "Appartements"
        when /terr|foret|bois/ then
          # Terrain
          return BienType.find_or_create "Terrains"
        when /bureau|commerc|entreprise|loca|boutique|droit|bail|indus|hotel|bar|particulier|moulin|meuliere|institut|centre|restaurant|gites|boulangerie|patisserie|boucherie|charcuterie|cafe|camping|parfumerie|coiffure/ then
          # Locaux commerciaux / Commerces
          return BienType.find_or_create "Commerces et Locaux commerciaux"
        when /garage|box|parking|stationnement/ then
          # Parkings / Garages
          return BienType.find_or_create "Parkings et Garages"
        when /immeuble|batiment|immobilier|ensemble|entrepot|hangar|entrepot|usine/ then
          # Bâtiments
          return BienType.find_or_create "Batiments"
        else
          # Autres
          return BienType.find_or_create "Autre"
        end
  end

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

end
