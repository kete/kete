require 'spec_helper'

feature 'Anonymous users' do
  it 'can view the homepage' do
    visit '/'
    expect(current_path).to eq('/')
    expect(page).to have_content('Welcome to Your New Kete Site')
  end
end

feature 'User registration' do
  it 'the page loads' do
    visit '/'
    click_on 'Register'
    expect(current_path).to eq('/en/site/account/signup')
  end
end
