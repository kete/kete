require 'spec_helper'

describe 'Anonymous users' do
  it 'can view the homepage' do
    visit '/'
    expect(page).to have_content('Welcome to Your New Kete Site')
  end
end
