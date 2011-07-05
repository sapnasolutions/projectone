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
  belongs_to :client
  
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
