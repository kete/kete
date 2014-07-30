require 'spec_helper'

feature "Page header Links" do
  it "displays the links" do
    visit "/"
    expect(page.html).to have_text 'Adopt an Anzac'
  end
end

