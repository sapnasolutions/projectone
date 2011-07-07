class Passerelle < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    type   :string
    params :string
    timestamps
  end

  belongs_to :installation

  has_many :executions, :dependent => :destroy
  has_many :biens, :dependent => :destroy
  
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
