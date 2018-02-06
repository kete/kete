# frozen_string_literal: true

require 'spec_helper'

describe AudioRecording do
  it 'does not blow up when you initialize it' do
    AudioRecording.new
  end
end
