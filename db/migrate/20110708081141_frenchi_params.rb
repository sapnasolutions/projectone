class FrenchiParams < ActiveRecord::Migration
  def self.up
    rename_column :passerelles, :software, :logiciel
    rename_column :passerelles, :params, :parametres
  end

  def self.down
    rename_column :passerelles, :logiciel, :software
    rename_column :passerelles, :parametres, :params
  end
end
