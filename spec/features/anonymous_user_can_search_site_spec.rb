require 'spec_helper'

describe "An anonymous user can search the site" do

  it "seeds should have loaded" do
    expect(User.count).to eq(2)
    expect(Basket.count).to eq(4)
  end

  it "should work" do
    visit '/'
    within '#head-search-wrapper' do
      fill_in 'search_terms', with: 'maori battilion'
      click 'Go'
    end

    expect(page).to have_content 'ANZAC Day around Horowhenua'
  end
end
