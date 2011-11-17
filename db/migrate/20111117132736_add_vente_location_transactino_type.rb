class AddVenteLocationTransactinoType < ActiveRecord::Migration
  def self.up
	if ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql"
		ActiveRecord::Base.connection.execute("TRUNCATE bien_transactions")
	elsif ActiveRecord::Base.connection.instance_values["config"][:adapter] == "sqlite3"
		ActiveRecord::Base.connection.execute("DELETE FROM bien_transactions")
		ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='bien_transactions'")
	end
	BienTransaction.create :id => 1, :nom => "Vente"
	BienTransaction.create :id => 2, :nom => "Location"
  end

  def self.down
	if ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql"
		ActiveRecord::Base.connection.execute("TRUNCATE bien_transactions")
	elsif ActiveRecord::Base.connection.instance_values["config"][:adapter] == "sqlite3"
		ActiveRecord::Base.connection.execute("DELETE FROM bien_transactions")
		ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='bien_transactions'")
	end
  end
end
