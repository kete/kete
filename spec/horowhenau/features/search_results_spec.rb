require 'spec_helper'

feature "Search results" do

  before(:each) do
    visit "/"
    within("#main-nav") do
      click_link('Browse')
    end
  end

  it "Searching works" do
    expect(page.status_code).to be(200)
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.generic-result-header')).to have_text('Percy NATION')
  end

  it "Related items summary is displayed" do
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.generic-result-related')).to have_text('Related: 2 Topics and 5 Still images')
    expect(first_result.find('.topic-result-related-images')).to have_css('img', count: 5)
  end

  it "Related items images load" do
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.topic-result-related-images')).to have_css('img', count: 5)
  end
end

