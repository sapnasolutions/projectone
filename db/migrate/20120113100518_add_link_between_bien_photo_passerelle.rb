class AddLinkBetweenBienPhotoPasserelle < ActiveRecord::Migration
  def self.up
	add_column :bien_photos, :passerelle_id, :integer
  end

  def self.down
	remove_column :bien_photos, :passerelle_id
  end
end
