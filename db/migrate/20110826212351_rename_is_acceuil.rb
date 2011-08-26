class RenameIsAcceuil < ActiveRecord::Migration
  def self.up
    rename_column :biens, :is_acceuil, :is_accueil
  end

  def self.down
    rename_column :biens, :is_accueil, :is_acceuil
  end
end
