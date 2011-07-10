class ChangePasserelleParametresTypeToText < ActiveRecord::Migration
  def self.up
    change_column :passerelles, :parametres, :text, :limit => nil
  end

  def self.down
    change_column :passerelles, :parametres, :string
  end
end
