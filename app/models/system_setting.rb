class SystemSetting < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 255

  def self.find_by_name(name)
    first(:conditions => ["name = ?", name.to_s]) unless name.nil?
  end

  def self.[](name)
    return unless name
    setting = find_by_name(name)
    setting.value if setting
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

