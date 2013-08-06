require_relative './db_connection'

module Searchable
  def where(params)
    sql_keys = params.keys
    sql_keys.map! do |key|
      "#{key} = ?"
    end
    sql_values = params.values

    query_rows = DBConnection.execute(<<-SQL, *sql_values)
      SELECT * FROM #{self.table_name}
              WHERE #{sql_keys.join(" AND ")}
    SQL

    self.parse_all(query_rows)
  end
end