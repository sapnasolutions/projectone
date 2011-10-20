class AddTousAccueilOption < ActiveRecord::Migration
  def self.up
	add_column :passerelles, :tous_accueil, :boolean
  end

  def self.down
	remove_column :passerelles, :tous_accueil
  end
end
