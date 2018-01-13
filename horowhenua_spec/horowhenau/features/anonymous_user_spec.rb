require 'spec_helper'

feature 'Anonymous users' do
  it 'are asked to login if they try to see list of members' do
    visit '/en/site/members/list'
    expect(current_path).to eq('/en/site/baskets/permission_denied')
  end

  it 'cannot see a link to the list of members on the homepage' do
    visit '/'
    expect(page).to_not have_link('Members')
  end
end
