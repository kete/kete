require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class BetterSendFileTest < Test::Unit::TestCase
  
  # James Stradling <james@katipo.co.nz>
  # Currently there are not tests as due to the dependency on the Nginx server and the 
  # need to configure a test application for testing, this is currently not worth 
  # implementing, IMHO. Suggestions welcome.
  
  def test_no_tests
    flunk "Tests not implemented"
  end
  
end