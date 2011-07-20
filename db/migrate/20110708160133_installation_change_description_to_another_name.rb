class InstallationChangeDescriptionToAnotherName < ActiveRecord::Migration
  def self.up
    rename_column :installations, :description, :informations_supplementaires
  end

  def self.down
    rename_column :installations, :informations_supplementaires, :description
  end
end
