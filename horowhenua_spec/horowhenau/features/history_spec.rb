require 'spec_helper'

describe "History" do
  examples = {
    audio:    '/en/site/audio/2-anzac-speech-by-dominique-cooreman',
    video:    '/en/site/video/58-mayors-duffys-speech-it-ended-with-a-bang',
    topic:    '/en/site/topics/196-levin-pottery-club',
    image:    '/en/site/images/20237-the-levin-orchid-society-show-august-2012-0241',
    document: '/en/site/documents/194-page-8-50th-jubilee-commemoration-supplement',
    web_link: '/en/site/web_links/25-see-page-14-of-this-pdf-for-more-information-on-james-bennie'
  }

  examples.each do |type, url|
    it "#{type} history works correctly" do
      visit url
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
end
