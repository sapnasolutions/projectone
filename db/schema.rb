# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120119110743) do

  create_table "bien_emplacements", :force => true do |t|
    t.string   "position_gps"
    t.string   "code_postal"
    t.string   "pays"
    t.string   "ville"
    t.string   "addresse"
    t.string   "secteur"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bien_photos", :force => true do |t|
    t.integer  "ordre"
    t.string   "titre"
    t.text     "attributs"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "bien_id"
    t.string   "hashsum"
    t.integer  "passerelle_id"
  end

  add_index "bien_photos", ["bien_id"], :name => "index_bien_photos_on_bien_id"

  create_table "bien_transactions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "nom"
  end

  create_table "bien_types", :force => true do |t|
    t.string   "nom"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "biens", :force => true do |t|
    t.integer  "nb_piece"
    t.integer  "prix"
    t.integer  "surface"
    t.integer  "surface_terrain"
    t.string   "titre"
    t.text     "description"
    t.date     "date_disponibilite"
    t.string   "statut"
    t.integer  "nb_chambre"
    t.integer  "valeur_dpe"
    t.integer  "valeur_ges"
    t.string   "classe_dpe"
    t.string   "class_ges"
    t.string   "reference"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bien_emplacement_id"
    t.integer  "bien_transaction_id"
    t.integer  "bien_type_id"
    t.integer  "passerelle_id"
    t.boolean  "is_accueil"
  end

  add_index "biens", ["bien_emplacement_id"], :name => "index_biens_on_bien_emplacement_id"
  add_index "biens", ["bien_transaction_id"], :name => "index_biens_on_bien_transaction_id"
  add_index "biens", ["bien_type_id"], :name => "index_biens_on_bien_type_id"
  add_index "biens", ["passerelle_id"], :name => "index_biens_on_passerelle_id"

  create_table "clients", :force => true do |t|
    t.string   "name"
    t.string   "raison_social"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "execution_source_files", :force => true do |t|
    t.string   "hashsum"
    t.text     "attributs"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "execution_id"
  end

  add_index "execution_source_files", ["execution_id"], :name => "index_execution_source_files_on_execution_id"

  create_table "executions", :force => true do |t|
    t.string   "type_exe"
    t.text     "description"
    t.string   "statut"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "passerelle_id"
  end

  add_index "executions", ["passerelle_id"], :name => "index_executions_on_passerelle_id"

  create_table "installations", :force => true do |t|
    t.string   "informations_supplementaires"
    t.string   "code_acces_distant"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id"
    t.integer  "execution_source_file_id"
  end

  add_index "installations", ["client_id"], :name => "index_installations_on_client_id"

  create_table "passerelles", :force => true do |t|
    t.string   "logiciel"
    t.string   "parametres"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "installation_id"
    t.boolean  "tous_accueil"
  end

  add_index "passerelles", ["installation_id"], :name => "index_passerelles_on_installation_id"

  create_table "users", :force => true do |t|
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "name"
    t.string   "email_address"
    t.boolean  "administrator",                           :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                                   :default => "invited"
    t.datetime "key_timestamp"
  end

  add_index "users", ["state"], :name => "index_users_on_state"

end
