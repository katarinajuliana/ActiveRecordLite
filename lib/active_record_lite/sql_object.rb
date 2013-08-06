require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name.underscore
  end

  def self.all
    query_rows = DBConnection.execute("SELECT * FROM #{self.table_name}")
    self.parse_all(query_rows)
  end

  def self.find(id)
    result = DBConnection.execute("SELECT * FROM #{self.table_name} WHERE id = ?", id)
    self.parse_all(result).first
  end

  def create
    sql_attrs = self.class.attributes.select { |attr| attr != :id }
    question_marks = ["?"] * sql_attrs.size
    attr_values = attribute_values

    DBConnection.execute(<<-SQL, *attr_values)
      INSERT INTO #{self.class.table_name} (#{sql_attrs.join(", ")})
           VALUES (#{question_marks.join(", ")})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    sql_attrs = self.class.attributes.select { |attr| attr != :id }
    sql_attrs.map! do |attr_name|
      "#{attr_name} = ?"
    end

    attr_values = attribute_values
    attr_values << self.id

    DBConnection.execute(<<-SQL, *attr_values)
      UPDATE #{self.class.table_name}
         SET #{sql_attrs.join(", ")}
       WHERE id = ?
    SQL
  end

  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  def attribute_values
    values = self.class.attributes.select { |attr| attr != :id }

    values.map! do |attr_name|
      send(attr_name)
    end

    values
  end
end
