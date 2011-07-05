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

ActiveRecord::Schema.define(:version => 20110705150748) do

  create_table "clients", :force => true do |t|
    t.string   "name"
    t.string   "raison_social"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "executions", :force => true do |t|
    t.string   "type"
    t.text     "description"
    t.string   "statut"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "passerelle_id"
  end

  add_index "executions", ["passerelle_id"], :name => "index_executions_on_passerelle_id"

  create_table "installations", :force => true do |t|
    t.text     "description"
    t.string   "code_acces_distant"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id"
  end

  add_index "installations", ["client_id"], :name => "index_installations_on_client_id"

  create_table "passerelles", :force => true do |t|
    t.string   "type"
    t.string   "params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "installation_id"
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
