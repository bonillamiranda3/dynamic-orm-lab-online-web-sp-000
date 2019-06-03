require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def initialize(options={})
      options.each do |property, value|
        self.send("#{property}=", value)
      end
    end

    def self.table_name
      self.to_s.pluralize.downcase
    end

    def self.column_names
      DB[:conn].results_as_hash = true
      sql = "PRAGMA table_info('#{self.table_name}')"
      table_info = DB[:conn].execute(sql)
      column_names = []
      table_info.each do |column|
        column_names << column["name"]
      end
      column_names.compact
    end

    def table_name_for_insert
      self.class.table_name
    end

    def col_names_for_insert
      names = self.class.column_names.drop(1)
      names.join(", ")
    end

    def values_for_insert
      values = []
      self.class.column_names.each do |col_name|
        values << "'#{send(col_name)}'" unless send(col_name).nil?
      end
      values.join(", ")
    end

    def save
      sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
      DB[:conn].execute(sql)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
     end

    def self.find_by_name(name)
      sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
      DB[:conn].execute(sql)
    end

    def self.find_by(attribute)
      sql = <<-SQL
        SELECT *
        FROM #{self.table_name}
        WHERE #{attribute.keys.first.to_s} = '#{attribute.values.first.to_s}'
      SQL
      DB[:conn].execute(sql)
    end
  end
