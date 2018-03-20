# frozen_string_literal: true

require 'spec_helper'

feature 'Membership management', js: true do
  scenario 'Admin can view membership list' do
    sign_in
    within '#basket-toolbox' do
      click_on 'members'
    end
    expect(page).to have_text('Site Members')
  end
end
