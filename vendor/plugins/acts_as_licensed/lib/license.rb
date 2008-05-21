class License < ActiveRecord::Base
  
  class << self
    
    def find_available
      License.find(:all, :conditions => ['is_available', true])
    end
    
  end
  
  def title
    name
  end
  
end
