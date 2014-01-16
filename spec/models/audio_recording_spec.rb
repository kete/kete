require 'spec_helper'

describe AudioRecording do
  let(:audio_recording) { AudioRecording.new }

  it "does not blow up when you initialize it" do
    audio_recording
  end

  it "can be saved to the database with minimal data filled in" do
    audio_recording_attrs = {
      title: "Ruby's Rock Steady",
      #description: "Sweet and dandy. Straight out of Jamaica.",
      filename: "ruby_rr.wav",
      content_type: "audio/mpeg",
      size: 32,
      #parent_id: ,
      basket_id: 1
    }
    audio_recording = AudioRecording.new(audio_recording_attrs)

    expect(audio_recording).to be_valid
    expect { audio_recording.save! }.to_not raise_error
  end
end 
