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
  belongs_to :execution_source_file

  has_many :passerelles, :dependent => :destroy
  
  def get_last_firmware
	self.execution_source_file = ExecutionSourceFile.order_by("updated_at").select{ |esf|
		esf.attributs.to_s.to_hashtribute["type"] == "firmware"
	}.last
	self.save!
  end
  
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
