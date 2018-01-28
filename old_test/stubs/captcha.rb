# Mock for captcha
class Captcha
  attr_accessor :id
  attr_accessor :imageblob

  def text
    "test"
  end

  def text=(value)
    # do nothing because we need something we know
  end

  def save
    # we fake an ActiveRecord save here
    id = 1
  end

  class << self
    def find(*args)
      new
    end
  end
end
