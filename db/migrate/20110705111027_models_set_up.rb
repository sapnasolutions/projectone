class ModelsSetUp < ActiveRecord::Migration
  def self.up
    create_table :clients do |t|
      t.string   :name
      t.string   :raison_social
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :executions do |t|
      t.string   :type
      t.string   :description
      t.string   :statut
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :passerelle_id
    end
    add_index :executions, [:passerelle_id]

    create_table :passerelles do |t|
      t.string   :type
      t.string   :params
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :installation_id
    end
    add_index :passerelles, [:installation_id]

    create_table :installations do |t|
      t.text     :description
      t.string   :code_acces_distant
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :client_id
    end
    add_index :installations, [:client_id]
  end

  def self.down
    drop_table :clients
    drop_table :executions
    drop_table :passerelles
    drop_table :installations
  end
end
