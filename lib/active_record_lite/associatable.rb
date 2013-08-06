require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table
    @other_class_name.constantize.table_name
  end
end

class BelongsToAssocParams < AssocParams
  attr_accessor :primary_key, :foreign_key

  def initialize(name, params)
    @other_class_name = params[:class_name]
    @other_class_name ||= name.to_s.camelize

    @primary_key = params[:primary_key]
    @primary_key ||= :id

    @foreign_key = params[:foreign_key]
    @foreign_key ||= "#{name}_id".to_sym
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_accessor :primary_key, :foreign_key

  def initialize(name, params, self_class)
    @other_class_name = params[:class_name]
    @other_class_name ||= name.to_s.singularize.camelize

    @primary_key = params[:primary_key]
    @primary_key ||= :id

    @foreign_key = params[:foreign_key]
    @foreign_key ||= "#{self_class.underscore}_id".to_sym
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps

    self.send(:define_method, name) do
      @other_class = aps.other_class
      @other_table_name = aps.other_table

      result = DBConnection.execute(<<-SQL, self.send(aps.foreign_key))
        SELECT *
          FROM #{@other_table_name}
         WHERE #{aps.primary_key} = ?
      SQL

      aps.other_class.parse_all(result)
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self)

    self.send(:define_method, name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.primary_key))
        SELECT *
          FROM #{aps.other_table}
         WHERE #{aps.foreign_key} = ?
      SQL

      aps.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    first_params = assoc_params[assoc1]

    self.send(:define_method, name) do
      other_params = first_params.other_class.assoc_params
      second_params = other_params[assoc2]
      result = DBConnection.execute(<<-SQL, self.send(first_params.foreign_key))
        SELECT *
          FROM #{first_params.other_table}  AS first_assoc
          JOIN #{second_params.other_table} AS second_assoc
            ON first_assoc.#{second_params.foreign_key} = second_assoc.#{second_params.primary_key}
         WHERE first_assoc.#{first_params.primary_key} = ?
      SQL
    end
  end
end
