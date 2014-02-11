require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable
  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name; tries to convert the class name if none is given
  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    DBConnection.execute(<<-SQL
      SELECT
        *
      FROM
        "#{self.table_name}"

        SQL
        )
      .map {|attr_hash| self.new(attr_hash)}
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    id_array = DBConnection.execute(<<-SQL, :id => id
      SELECT
        *
      FROM
        "#{self.table_name}"
      WHERE
        "#{self.table_name}".id = :id

      SQL
    )
    return self.new(id_array[0]) unless id_array[0].nil?
    nil
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection


  # call either create or update depending if id is nil.
  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  # helper method to return values of the attributes.
  def attribute_values
    self.class.attributes.map do |attribute|
      self.send(attribute)
    end
  end

private
  def create
    attr_names = self.class.send(:attributes).join(",")
    q_marks = attribute_values.map {|value| '?'}.join(",")
    attr_values = self.attribute_values

    DBConnection.execute(<<-SQL, attr_values
      INSERT INTO
        #{self.class.table_name}(#{attr_names})
      VALUES
        (q_marks)

      SQL
    )
      self.id = DBConnection.last_insert_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    attr_names = self.class.send(:attributes)
    set_line = attr_names.map {|attr_name| "#{attr_name} = ?"}.join(", ")
    attr_values = self.attribute_values

    DBConnection.execute(<<-SQL, attr_values
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = #{self.id}

      SQL
    )
  end
end
