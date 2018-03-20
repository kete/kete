# frozen_string_literal: true

require 'spec_helper'

describe Document do
  let(:document) { Document.new }

  it 'does not blow up when you initialize it' do
    document
  end
end
