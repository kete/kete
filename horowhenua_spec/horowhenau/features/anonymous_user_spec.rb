require 'spec_helper'

describe 'Anonymous users' do
  it 'are asked to login if they try to see list of members' do
    visit '/en/site/members/list'
    expect(current_path).to eq('/en/site/baskets/permission_denied')
  end

  it 'cannot see a link to the list of members on the homepage' do
    visit '/'
    expect(page).not_to have_link('Members')
  end
end
