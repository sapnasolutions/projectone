class Execution < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    type_exe    :string
    description :text
    statut      :string
    timestamps
  end

  belongs_to :passerelle
  has_one :execution_source_file
  
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
