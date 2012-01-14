class AddVersionSourceBinInstalFile < ActiveRecord::Migration
  def self.up
  	add_column :installations, :fichier_id, :integer
	add_column :installations, :adresse_fichier, :string
  end

  def self.down
  	remove_column :installations, :fichier_id
	remove_column :installations, :adresse_fichier
  end
end
