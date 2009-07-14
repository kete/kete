require 'brain_buster'
require 'brain_buster_system'

# Kieran Pilkington, 2009-05-25
# Fixing issue with inclusion into Rails 2.3 ApplicationController
# ActionController::Base.class_eval { include BrainBusterSystem }
ActionController::Base.send :include, BrainBusterSystem
