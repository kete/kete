# frozen_string_literal: true

# Change secret_token when you deploy to production, or I'll throw my toys.

# This is a secret key for verifying the integrity of signed cookies.
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

if Rails.env.test? || Rails.env.development?
  KeteApp::Application.config.secret_token = 'a05fb67d1237cf87cf04a30a7a141d3c1377ae6db1985f15fefa745684790c320e672bda6d9201eea2013f3936bdf57f834006ab4df473c4590cb79944e12a52'
else
  raise "You must set a secret token in ENV['SECRET_TOKEN'] or in config/initializers/secret_token.rb" if ENV['SECRET_TOKEN'].blank?
  KeteApp::Application.config.secret_token = ENV['SECRET_TOKEN']
end
