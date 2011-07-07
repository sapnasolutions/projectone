class AddHashsumBienPhoto < ActiveRecord::Migration
  def self.up
    add_column :bien_photos, :hashsum, :string
  end

  def self.down
    remove_column :bien_photos, :hashsum
  end
end
