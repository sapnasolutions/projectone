class BienEmplacement < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    position_gps :string
    code_postal  :string
    pays         :string
    ville        :string
    addresse     :string
    secteur      :string
    timestamps
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
