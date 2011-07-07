class CorrectRelationBienPasserelleAddPhoto < ActiveRecord::Migration
  def self.up
    rename_column :biens, :client_id, :passerelle_id

    add_column :bien_photos, :bien_id, :integer

    remove_index :biens, :name => :index_biens_on_client_id rescue ActiveRecord::StatementInvalid
    add_index :biens, [:passerelle_id]

    add_index :bien_photos, [:bien_id]
  end

  def self.down
    rename_column :biens, :passerelle_id, :client_id

    remove_column :bien_photos, :bien_id

    remove_index :biens, :name => :index_biens_on_passerelle_id rescue ActiveRecord::StatementInvalid
    add_index :biens, [:client_id]

    remove_index :bien_photos, :name => :index_bien_photos_on_bien_id rescue ActiveRecord::StatementInvalid
  end
end
