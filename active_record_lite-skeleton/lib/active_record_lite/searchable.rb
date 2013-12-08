require_relative './db_connection'

module Searchable
  # takes a hash like { :attr_name => :search_val1, :attr_name2 => :search_val2 }
  # map the keys of params to an array of  "#{key} = ?" to go in WHERE clause.
  # Hash#values will be helpful here.
  # returns an array of objects
  def where(params)
    where_clause = params.keys
                         .map {|key| "#{key} = ?"}
                         .join(" AND ")
    attr_values = params.values
    DBConnection.execute(<<-SQL, attr_values
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_clause}

    SQL
    )
    .map {|attr_hash| self.new(attr_hash)}

  end

end