require 'spec_helper'


def update_timestamp(item)
  title = item.title

  item.update_attribute(:title, title+"CHANGE")
  item.update_attribute(:title, title)
end

def one_day_ago
  (DateTime.now - 1.day).iso8601
end

feature "RSS Feeds" do
  scenario "RSS links in footer are disabled" do
    visit "/"
    expect(page).to_not have_css("#linkToRSS")
  end

  scenario "RSS links in <head> are disabled" do
    visit "/"
    expect(page).to_not have_css("link[type='application/rss+xml']", visible: false)
  end

  it "for audio_recordings are available" do
    item = AudioRecording.find(1)
    update_timestamp(item)

    visit "/en/site/audio/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)
  end

  it "for documents are available" do
    item = Document.find(104)
    update_timestamp(item)

    visit "/en/site/documents/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)
  end

  it "for still_images are available" do
    item = StillImage.find(251)
    update_timestamp(item)

    visit "/en/site/images/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)
  end

  pending "for topics are available" do
    item = Topic.find(171)
    update_timestamp(item)
    
    visit "/en/site/topics/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)
  end

  it "for videos are available" do
    item = Video.find(3)
    update_timestamp(item)

    visit "/en/site/video/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)
  end

  it "for web_links are available" do
    item = WebLink.find(36)
    update_timestamp(item)

    visit "/en/site/web_links/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)
  end
end
