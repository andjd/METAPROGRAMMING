require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    columns = params.keys
    values = params.values
    where_string =
    sql_out = DBConnection.execute(<<-SQL, *values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{columns.join(' = ? AND ')} = ?
    SQL

    self.parse_all(sql_out)
  end

end

class SQLObject
  extend Searchable
end
