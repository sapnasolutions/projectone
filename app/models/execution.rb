class Execution < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    type        :string
    description :text
    statut      :string
    timestamps
  end

  belongs_to :passerelle
  
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
