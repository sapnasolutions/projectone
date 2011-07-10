class ChangePasserelleTypeToSoftware < ActiveRecord::Migration
  def self.up
    rename_column :passerelles, :type, :software
  end

  def self.down
    rename_column :passerelles, :software, :type
  end
end
