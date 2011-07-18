class AddNameToTransaction < ActiveRecord::Migration
  def self.up
    add_column :bien_transactions, :nom, :string
  end

  def self.down
    remove_column :bien_transactions, :nom
  end
end
