require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.
class SQLObject
  def self.columns
    cols = DBConnection.execute2(<<-SQL).first.map(&:to_sym)
        SELECT * FROM #{table_name}
      SQL
  end

  def self.new_setter(col)

    define_method(col.to_s + "=") do |new_col_val|
      @attributes.merge! Hash[col, new_col_val]
    end
  end

  def self.new_getter(col)
    define_method(col) do
      @attributes[col]
    end
  end

  def self.finalize!
    cols = columns
    @attributes = Hash.new

    cols.each do |col|
      new_setter(col)
      new_getter(col)
    end

    define_method(:attributes) do
      @attributes
    end
    table_name = 'humans' if self.name == 'Human'
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ? @table_name : self.name.tableize
  end

  def self.all
    name = self.name.tableize
    sql_out = DBConnection.execute(<<-SQL)
      SELECT #{name}.* FROM #{name}
    SQL
    self.parse_all(sql_out)
  end

  def self.parse_all(results)
    return nil if results.length.zero?
    results.map do |params|
      self.new(params)
    end
  end

  def self.find(id)
    sql_out = DBConnection.execute(<<-SQL, id)
      SELECT #{table_name}.* FROM #{table_name} WHERE id = ?
    SQL
    out = self.parse_all(sql_out)
    out.nil? ? nil : out.first
  end

  def initialize(params = {})
    attrs = params.reduce(Hash.new) do |memo, pair|
      atr, val = pair
      unless self.class.columns.include?(atr.to_sym)
        raise ArgumentError.new "unknown attribute '#{atr}'"
      end
      memo.merge (Hash[atr.to_sym, val])
    end
    @attributes = self.class.instance_variable_get(:@attributes).merge attrs
  end

  def attributes
    @attributes
  end

  def attribute_values
    @attributes.values
  end

  def insert
    attrs_less_id = @attributes.keep_if { |key, _| key != :id}
    q_marks = (["?"] * attrs_less_id.length).join(", ")

    DBConnection.execute(<<-SQL, *attrs_less_id.values.map(&:to_s))
      INSERT INTO #{self.class.table_name}
      (#{attrs_less_id.keys.join(", ")})
      VALUES (#{q_marks})
    SQL

    self.attributes[:id] = DBConnection.last_insert_row_id

    self
  end

  def update
    attrs_less_id = @attributes.keep_if { |key, _| key != :id}
    set_string = attrs_less_id.keys.join(" = ?, ") + " = ?"

    DBConnection.execute(<<-SQL, *attrs_less_id.values.map(&:to_s), self.id)
      UPDATE #{self.class.table_name}
      SET #{set_string}
      WHERE id = ?
    SQL

    self.attributes[:id] = DBConnection.last_insert_row_id

    self
  end

  def save
    # ...
  end
end
