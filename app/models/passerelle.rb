class Passerelle < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    logiciel   	:string
    parametres 	:string
	tous_accueil :boolean
	#parametres 	:text
	# or create a model named parametres, bug with editor and text or hash
    timestamps
  end

  belongs_to :installation

  has_many :executions, :dependent => :destroy
  has_many :biens, :dependent => :destroy
  has_many :bien_photos
  
  #typed_serialize :parametres, Hash
  
  def name
	return self.logiciel
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
