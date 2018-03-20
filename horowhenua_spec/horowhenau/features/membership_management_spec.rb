require 'spec_helper'

describe 'Membership management', js: true do
  it 'Admin can view membership list' do
    sign_in
    within '#basket-toolbox' do
      click_on 'members'
    end
    expect(page).to have_text('Site Members')
  end
end
