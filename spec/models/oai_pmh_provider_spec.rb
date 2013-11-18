require 'spec_helper'

describe OaiPmhRepositoryProvider do
  it "does not blow up when you initialize it" do
    # EOIN: this blows up but I'm not sure why - strange class declaration, need to investigate more
    foo = OaiPmhRepositoryProvider.new
  end
end

