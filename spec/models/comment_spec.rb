require 'spec_helper'

describe Comment do
  it 'does not blow up when you initialize it' do
    described_class.new
  end
end
