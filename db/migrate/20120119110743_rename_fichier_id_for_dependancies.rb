class RenameFichierIdForDependancies < ActiveRecord::Migration
  def self.up
	remove_column :installations, :adresse_fichier
	rename_column :installations, :fichier_id, :execution_source_file_id
  end

  def self.down
	add_column :installations, :adresse_fichier, :string
	rename_column :installations, :execution_source_file_id, :fichier_id
  end
 
end
