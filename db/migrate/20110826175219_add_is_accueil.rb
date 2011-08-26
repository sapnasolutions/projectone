class AddIsAccueil < ActiveRecord::Migration
  def self.up
    add_column :biens, :is_acceuil, :boolean
  end

  def self.down
    remove_column :biens, :is_accueil
  end
end
