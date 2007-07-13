class SystemSetting < ActiveRecord::Base
  # Walter McGinnis, 2007-07-12
  # don't allow special characters in name
  # since will eventually make them into a constant name
  validates_format_of :name, :with => /^[^\'\"<>\&,\/\\\?]*$/, :message => ": \', \\, /, &, \", ?, <, and > characters aren't allowed"

  def self.find_by_name(name)
    super(name.to_s)
  end

  def self.[](name)
    find_by_name(name)
  end

  def to_f
    value.to_f
  end

  def to_i
    value.to_i
  end

  def to_s
    value
  end
end
