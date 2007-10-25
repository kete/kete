class Test::Unit::TestCase
  
  def self.inherited(sub)
    super
    if sub.to_s =~ /\b(.+?Controller)Test$/ && instance_eval($1)
      sub.class_eval do
        attr_accessor :controller, :request, :response
        
        def initialize(name)
          super
          if self.class.to_s =~ /\b(.+?Controller)Test$/
            @controller = instance_eval($1).new
            @request = ActionController::TestRequest.new
            @response = ActionController::TestResponse.new
            instance_eval(self.class.to_s.gsub(/Test$/,'')).class_eval do
              def rescue_action(e) raise e end
            end
          end
        end
      end
    end
    
  rescue NameError
  end
  
end
