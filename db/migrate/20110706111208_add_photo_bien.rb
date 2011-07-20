class AddPhotoBien < ActiveRecord::Migration
  def self.up
    create_table :bien_photos do |t|
      t.integer  :ordre
      t.string   :titre
      t.text     :attributs
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :bien_photos
  end
end
