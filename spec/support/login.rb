# frozen_string_literal: true

def login(user)
  visit '/'
  click_on 'Login'
  fill_in 'Login:', with: user.login
  fill_in 'Password:', with: user.password
  find('.login-button').click
end
