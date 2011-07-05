class CorrectDescrpitionExecutinoType < ActiveRecord::Migration
  def self.up
    change_column :executions, :description, :text, :limit => nil
  end

  def self.down
    change_column :executions, :description, :string
  end
end
