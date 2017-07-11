require 'spec_helper'

describe WebLink do

  it 'does not blow up when you initialize it' do
    WebLink.new
  end

  it 'validates URLs' do
    wl = WebLink.new(url: 'http://www.foo.com', title: 'Some interesting link')
    expect(wl).to be_valid
  end
end
