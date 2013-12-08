require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table
    @other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams

  attr_accessor :other_class_name, :primary_key, :foreign_key,
                :other_class, :other_table_name

  def initialize(name, params)
    if params[:class_name].nil?
      @other_class_name = name.to_s.camelize
    else
      @other_class_name = params[:class_name]
    end
    if params[:primary_key].nil?
      @primary_key = "id"
    else
      @primary_key = params[:primary_key]
    end
    if params[:foreign_key].nil?
      @foreign_key = "#{name}_id"
    else
      @foreign_key = params[:foreign_key]
    end
    #@other_class = @other_class_name.constantize
    #@other_table_name = @other_class.table_name
  end

  def type
  end
end

class HasManyAssocParams < AssocParams

  attr_accessor :other_class_name, :primary_key, :foreign_key,
                :other_class, :other_table_name

  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params

  end

  def belongs_to(name, params = {})
    helper_params = BelongsToAssocParams.new(name, params)
    self.define_method(name) do
      @other_class = @other_class_name.constantize
      @other_table_name = @other_class.table_name
      results = DBConnection.execute(<<-SQL
        SELECT
          #{helper_params.other_table}.*
        FROM
          #{self.table_name}
        JOIN
          #{helper_params.other_table}
        ON
        #{helper_params.foreign_key} = #{helper_params.other_table.primary_key}
        WHERE
        #{helper_params.foreign_key} = #{helper_params.other_table.primary_key}

        SQL
      )
      self.parse_all(results)
    end
  end

  def has_many(name, params = {})
  end

  def has_one_through(name, assoc1, assoc2)
  end
end
