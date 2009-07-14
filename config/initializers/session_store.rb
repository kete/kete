# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_kete_session',
  :secret      => 'a05fb67d1237cf87cf04a30a7a141d3c1377ae6db1985f15fefa745684790c320e672bda6d9201eea2013f3936bdf57f834006ab4df473c4590cb79944e12a52'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
