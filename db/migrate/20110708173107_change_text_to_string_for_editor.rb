class ChangeTextToStringForEditor < ActiveRecord::Migration
  def self.up
    change_column :passerelles, :parametres, :string, :limit => 255

    change_column :installations, :informations_supplementaires, :string, :limit => 255
  end

  def self.down
    change_column :passerelles, :parametres, :text

    change_column :installations, :informations_supplementaires, :text
  end
end
