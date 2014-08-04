require 'spec_helper'

feature "History" do

  examples = {
    audio: '/en/audio/2-anzac-speech-by-dominique-cooreman',
    video: '/en/videos/57-daft-young-folk-band-perform',
    topic: '/en/topics/196-levin-pottery-club',
    image: '/en/images/20237-the-levin-orchid-society-show-august-2012-0241',
    document: '/en/documents/194-page-8-50th-jubilee-commemoration-supplement',
    web_link: '/en/web_links/23-organic-river-festival'
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
