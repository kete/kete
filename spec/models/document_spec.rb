require 'spec_helper'

describe Document do
  let(:document) { described_class.new }

  it 'does not blow up when you initialize it' do
    document
  end
end
