class AddExecutionSourceFileObject < ActiveRecord::Migration
  def self.up
    create_table :execution_source_files do |t|
      t.string   :hashsum
      t.text     :attrs
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :execution_source_files
  end
end
