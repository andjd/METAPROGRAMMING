require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key)


  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    relations = Hash[:foreign_key, (name.to_s + "_id").to_sym,
      :primary_key, :id,
      :class_name, "#{name.to_s.classify}"]

    relations.merge! options
    relations.each do |param, val|
      instance_variable_set "@" + param.to_s, val
    end

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    relations = (
      Hash[:foreign_key, ((self_class_name.to_s + "Id").underscore).to_sym,
      :primary_key, :id,
      :class_name, "#{name.to_s.classify}"])

    relations.merge! options
    relations.each do |param, val|
      instance_variable_set "@" + param.to_s, val
    end

  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    byebug
    options = BelongsToOptions.new(name, options = {})

    define_method(name) do
      a_key = options.foreign_key
      a_key_val = self.send(a_key)
      a_class = options.model_class
      #target_class =

      a_class.where({:id => a_key_val}).first
    end


  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
