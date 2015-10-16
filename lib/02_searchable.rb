require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
  def where(params)
    columns = params.keys
    values = params.values
    col_str = columns.map { |col| col.to_s + " = ?"}.join " AND "
    sql_out = DBConnection.execute(<<-SQL, *values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{col_str}
    SQL

    self.parse_all(sql_out)
  end

end

class SQLObject
  extend Searchable
end
