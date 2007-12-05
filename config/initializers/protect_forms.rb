# Walter McGinnis, 2007-12-03
# protect forms from receiving attacks
ActionController::Base.protect_from_forgery :secret => 'kete'

