require 'spec_helper'

describe OaiPmhRepositoryProvider do
  it 'does not blow up when you initialize it' do
    foo = described_class.new
  end
end
