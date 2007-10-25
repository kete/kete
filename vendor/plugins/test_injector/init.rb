if RAILS_ENV == 'test'  
  require 'test_injector'
  require 'test/unit'
  
  # tidy_functionals will break the mocha plugin - use at your own risk
  # require 'tidy_functionals'

  Test::Unit::TestCase.class_eval do
    include TestInjector
  end
end
