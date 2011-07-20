class RenameToAvoidPbWithRails < ActiveRecord::Migration
  def self.up
    rename_column :executions, :type, :type_exe

    rename_column :execution_source_files, :attrs, :attributs
  end

  def self.down
    rename_column :executions, :type_exe, :type

    rename_column :execution_source_files, :attributs, :attrs
  end
end
