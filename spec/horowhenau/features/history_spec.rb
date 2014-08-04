require 'spec_helper'

feature "History" do
  it "Topic history works" do
    visit "/en/topics/196-levin-pottery-club" # a topic
    click_on('History')

    # the page loads correctly
    expect(page.status_code).to be 200
    expect(page).to have_text "Revision History:"

    # there is a revision author avatar
    expect(page).to have_selector('.history-table .contributor .user_contribution_link_avatar')

    # There is a revision author name
    expect(find('.history-table').find('.contributor', match: :first).text.length).to be > 0
  end

  it "Image history works" do
    visit "/en/images/20237-the-levin-orchid-society-show-august-2012-0241" # an image

    click_on('History')

    # the page loads correctly
    expect(page.status_code).to be 200
    expect(page).to have_text "Revision History:"

    # there is a revision author avatar
    expect(page).to have_selector('.history-table .contributor .user_contribution_link_avatar')

    # There is a revision author name
    expect(find('.history-table').find('.contributor', match: :first).text.length).to be > 0
  end

  it "Document history works" do
    visit "/en/documents/194-page-8-50th-jubilee-commemoration-supplement" # a document

    click_on('History')

    # the page loads correctly
    expect(page.status_code).to be 200
    expect(page).to have_text "Revision History:"

    # there is a revision author avatar
    expect(page).to have_selector('.history-table .contributor .user_contribution_link_avatar')

    # There is a revision author name
    expect(find('.history-table').find('.contributor', match: :first).text.length).to be > 0
  end
end
