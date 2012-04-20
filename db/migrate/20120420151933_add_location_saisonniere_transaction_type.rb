class AddLocationSaisonniereTransactionType < ActiveRecord::Migration
  def self.up
    BienTransaction.create :id => 3, :nom => "Location saisonniere"
  end

  def self.down
    BienTransaction.find(3).destroy
  end
end
