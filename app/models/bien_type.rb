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
