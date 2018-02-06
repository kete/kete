# frozen_string_literal: true

require 'spec_helper'

describe ContentType do
  it 'does not blow up when you initialize it' do
    ContentType.new
  end
end
