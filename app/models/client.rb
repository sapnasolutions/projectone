class Client < ActiveRecord::Base

  hobo_model # Don't put anything above this
  
  fields do
    name          :string
    raison_social :string
    timestamps
  end
  
  has_many :installations, :dependent => :destroy

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
