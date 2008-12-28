require File.dirname(__FILE__) + '/../selenium_test_helper'

class AudioTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_add_audio
    open "/site/audio/new"
    assert_text_present "New audio recording"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present "6 errors prohibited this audio recording from being saved"
  end

  def test_edit_audio
    open "/site/audio/show/1"
    assert_text_present "Recording type"
    click_and_wait "link=Edit"
    select "audio_recording_basket_id", "label=About"
    type_from_hash { :audio_recording_title => 'Rails Example',
                     :audio_recording_tag_list => 'audio,demo,test',
                     :audio_recording_version_comment => 'This is an audio edit test.' }
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present ["AudioRecording was successfully updated.",
                         "Kete: About",
                         "Rails Example",
                         "Tags: test, demo, audio"]
    click_and_wait "link=Edit"
    select "audio_recording_basket_id", "label=Site"
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present "AudioRecording was successfully updated."
  end

end
