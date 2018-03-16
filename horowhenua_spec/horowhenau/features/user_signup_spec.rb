require 'spec_helper'

describe 'User sign-up' do
  it 'A user can sign-up' do
    user_attrs = {
      login: 'tester',
      user_name: 'Jane Tester',
      email: 'foo@bar.com',
      password: 'dummy'
    }

    visit '/'

    within('.user-nav') do
      click_link('Register')
    end

    fill_in 'Login:', with: user_attrs[:login]
    fill_in 'Email:', with: user_attrs[:email]
    fill_in 'Password:', with: user_attrs[:password]
    fill_in 'User name:', with: user_attrs[:user_name]
    fill_in 'Confirm password:', with: user_attrs[:password]
    check 'user[agree_to_terms]'
    click_button 'Sign up'
    expect(page).to have_text('Thanks for signing up!')
  end
end
