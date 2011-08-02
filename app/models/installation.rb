class Installation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    informations_supplementaires        :string
	#informations_supplementaires 	:text
	# or create a model named parametres, bug with editor and text or hash
    code_acces_distant :string
    timestamps
  end

  belongs_to :client

  has_many :passerelles, :dependent => :destroy
  
  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end
  
  def data_permitted?
	true
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
