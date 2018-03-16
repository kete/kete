# frozen_string_literal: true

require 'spec_helper'

feature 'Anonymous users' do
  it 'can view the homepage' do
    visit '/'
    expect(page).to have_content('Welcome to Your New Kete Site')
  end
end
