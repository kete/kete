require 'spec_helper'

describe "Page header Links" do
  it "displays the links" do
    visit "/"
    expect(page.html).to have_text 'Adopt an Anzac'
  end
end

