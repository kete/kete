class Basket < ActiveRecord::Base
  # set up authorization plugin
  acts_as_authorizable

end
