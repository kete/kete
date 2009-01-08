class SystemSetting < ActiveRecord::Base
  # Walter McGinnis, 2007-07-12
  # don't allow special characters in name
  # since will eventually make them into a constant name
  validates_format_of :name, :with => /^[^\'\"<>\&,\/\\\?]*$/, :message => ": \', \\, /, &, \", ?, <, and > characters aren't allowed"
  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of :name, :section

  def self.find_by_name(name)
    find(:first, :conditions => ["name = ?", name.to_s]) unless name.nil?
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

  # setting names
  # get transposed from "A Name" to "A_NAME"
  def constant_name
    name.upcase.gsub(/[^A-Z0-9\s_-]+/,'').gsub(/[\s-]+/,'_')
  end

  def constant_value
    constant_value = value
    # we don't need to eval certain setting values
    # like empty strings, hash or array definitions, or booleans
    if !constant_value.blank? and constant_value.match(/^([0-9\{\[]|true|false)/)
      # Serious potential security issue, we eval user inputed value at startup
      # for things that are recognized as boolean, integer, hash, or array
      # by regexp above
      # Make sure only knowledgable and AUTHORIZED people can edit System Settings
      constant_value = eval(value)
    end
    constant_value
  end

  def to_constant
    Object.const_set(constant_name, constant_value)
  end

  def push(additional_value)
    return false if self.value.include?(additional_value)
    self.value = self.value.gsub(']', ", \'#{additional_value}\']")
    save!
    true
  end

  # we use a non-validate method, since required_to_be_configured
  # is only really necessary in a specific context in a controller
  def add_error_if_required
    errors.add_to_base("This setting is required") if value.blank? and required_to_be_configured
    return true
  end

  def self.count_nil_required
    count(:conditions => ["required_to_be_configured = ? and value is null", true])
  end

  def self.not_completed
    count_nil_required > 0 ? true : false
  end
end
