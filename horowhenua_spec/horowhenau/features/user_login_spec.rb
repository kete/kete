# frozen_string_literal: true

require 'spec_helper'

feature 'User login' do
  it 'A site admin can login' do
    sign_in
    expect(page).to have_text('Logged in successfully')
  end

  describe 'As a logged in site admin' do
    it 'can logout' do
      sign_in
      click_link 'Logout'
      expect(page).to have_text('You have been logged out.')
    end

    it 'can see their account overview page' do
      sign_in
      click_link username
      expect(page).to have_text("Profile of #{username}")
    end

    it 'can view the list of members' do
      sign_in
      click_link 'Sitemap'

      site_row_in_table = "//tr[td[a[text()='Site']]]"
      find(:xpath, site_row_in_table).click_on("Members")
      expect(page).to have_text('Site Members')
    end
  end
end
