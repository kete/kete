# Mock for captcha
class Captcha
  
  def method_missing(m, *args)
    self.class.send(:eval, :attr_accessor, m)
    m *args
  end
  
  def text
    "test"
  end
  
  class << self
    def find(*args)
      return self.new
    end
  end
end