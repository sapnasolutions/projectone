class Client < ActiveRecord::Base

  hobo_model # Don't put anything above this
  
  fields do
    name          :string
    raison_social :string
    timestamps
  end
  
  has_many :installations, :dependent => :destroy

  def create
	super
	Dir.mkdir "#{$base_client_medias}/#{self.id}" unless File.exist? "#{$base_client_medias}/#{self.id}"
	return self
  end
  
  def destroy
	Dir.rmdir "#{$base_client_medias}/#{self.id}" if File.exist? "#{$base_client_medias}/#{self.id}"
	super
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
