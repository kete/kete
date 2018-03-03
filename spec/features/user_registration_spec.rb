require 'spec_helper'

describe 'User registration', js: true do
  it 'An anonymous user can register for an account' do
    user = FactoryGirl.attributes_for(:user)

    visit '/'
    click_on 'Register'
    fill_in 'Login:', with: user[:login]
    fill_in 'Email:', with: user[:email]
    fill_in 'Password:', with: user[:password]
    fill_in 'Confirm password:', with: user[:password]
    fill_in 'User name:', with: user[:display_name]
    check 'user[agree_to_terms]'
    click_on 'Sign up'

    expect(page).to have_content('Thanks for signing up')
  end

  it 'A user with an existing account can login' do
    # given ...
    user = FactoryGirl.create(:user, :activated)

    # when ...
    # we are testing the login process here so we don't use our #login helper
    # function as it would make this test less readable
    visit '/'
    click_on 'Login'
    fill_in 'Login:', with: user.login
    fill_in 'Password:', with: user.password
    find('.login-button').click

    # then ...
    expect(page).to have_content('Logged in successfully')
  end
end
