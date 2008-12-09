require 'factory_girl'

Factory.define :user do |u|
  u.login 'joe'
  u.email { |e| "#{e.login}@ketetest.co.nz".downcase }
  u.salt '7e3041ebc2fc05a40c60028e2c4901a81035d3cd'
  u.crypted_password '00742970dc9e6319f8019fd54864d3ea740f04b1' # test
  u.created_at Time.now.to_s(:db)
  u.updated_at Time.now.to_s(:db)
  u.activation_code 'admincode'
  u.activated_at Time.now.to_s(:db)
  u.agree_to_terms true
  u.security_code "a"
end
