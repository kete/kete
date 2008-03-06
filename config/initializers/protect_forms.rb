# Walter McGinnis, 2007-12-03
# protect forms from receiving attacks
KETE_SECRET = 'kete'
ActionController::Base.protect_from_forgery :secret => KETE_SECRET

