class LinkExecutionToSourceFile < ActiveRecord::Migration
  def self.up
    add_column :execution_source_files, :execution_id, :integer

    add_index :execution_source_files, [:execution_id]
  end

  def self.down
    remove_column :execution_source_files, :execution_id

    remove_index :execution_source_files, :name => :index_execution_source_files_on_execution_id rescue ActiveRecord::StatementInvalid
  end
end
