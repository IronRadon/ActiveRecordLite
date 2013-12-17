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
    if params[:class_name].nil?
      @other_class_name = name.to_s.singularize.camelize
    else
      @other_class_name = params[:class_name]
    end
    if params[:primary_key].nil?
      @primary_key = "id"
    else
      @primary_key = params[:primary_key]
    end
    if params[:foreign_key].nil?
      @foreign_key = "#{self_class}_id".downcase
    else
      @foreign_key = params[:foreign_key]
    end
  end

  def type
  end
end

module Associatable

  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    helper_params = BelongsToAssocParams.new(name, params)
    self.send(:define_method, name) do
      helper_params.other_class = helper_params.other_class_name.constantize
      helper_params.other_table_name = helper_params.other_class.table_name
      
      results = DBConnection.execute(<<-SQL, self.send(helper_params.foreign_key)
        SELECT
          #{helper_params.other_table_name}.*
        FROM
          #{helper_params.other_table_name}
        WHERE
        #{helper_params.primary_key} = ?
        SQL
      )
      helper_params.other_class.parse_all(results).first
    end
    self.assoc_params[name] = helper_params
  end

  def has_many(name, params = {})
    helper_params = HasManyAssocParams.new(name, params, self.class)
    self.send(:define_method, name) do
      helper_params.other_class = helper_params.other_class_name.constantize
      helper_params.other_table_name = helper_params.other_class.table_name
      results = DBConnection.execute(<<-SQL, self.send(helper_params.primary_key)
        SELECT
          #{helper_params.other_table_name}.*
        FROM
          #{helper_params.other_table_name}
        WHERE
        #{helper_params.foreign_key} = ?
        SQL
      )
      helper_params.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    
    self.send(:define_method, name) do
      through_options = self.class.assoc_params[assoc1]
      source_options = through_options.other_class.assoc_params[assoc2]
      p source_options.foreign_key
      
      values = []
      results = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key)
        SELECT
          #{source_options.other_table_name}.*
        FROM
          #{source_options.other_table_name}
        JOIN
          #{through_options.other_table_name}
        ON
          #{source_options.other_table_name}.id = #{source_options.foreign_key}
        WHERE
          #{through_options.other_table_name}.id = ?
        SQL
        )
        source_options.other_class.parse_all(results).first
    end

  end
end
