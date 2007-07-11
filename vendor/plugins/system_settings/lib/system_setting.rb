class SystemSetting < ActiveRecord::Base
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
