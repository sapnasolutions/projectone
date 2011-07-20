class AddingGoodsModels < ActiveRecord::Migration
  def self.up
    create_table :biens do |t|
      t.integer  :nb_piece
      t.integer  :prix
      t.integer  :surface
      t.integer  :surface_terrain
      t.string   :titre
      t.text     :description
      t.date     :date_disponibilite
      t.string   :statut
      t.integer  :nb_chambre
      t.integer  :valeur_dpe
      t.integer  :valeur_ges
      t.string   :classe_dpe
      t.string   :class_ges
      t.string   :reference
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :bien_emplacement_id
      t.integer  :bien_transaction_id
      t.integer  :bien_type_id
      t.integer  :client_id
    end
    add_index :biens, [:bien_emplacement_id]
    add_index :biens, [:bien_transaction_id]
    add_index :biens, [:bien_type_id]
    add_index :biens, [:client_id]

    create_table :bien_emplacements do |t|
      t.string   :position_gps
      t.string   :code_postal
      t.string   :pays
      t.string   :ville
      t.string   :addresse
      t.string   :secteur
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :bien_transactions do |t|
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :bien_types do |t|
      t.string   :nom
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :biens
    drop_table :bien_emplacements
    drop_table :bien_transactions
    drop_table :bien_types
  end
end
