require 'spec_helper'

feature "User login" do

  it "works" do
    visit "/"
    within(".user-nav") do
      click_link('Login')
    end

    within("form#login") do
      fill_in "Login", with: "eoinkelly"
      fill_in "Password", with: "iDHVrBKH2QeH"
      click_button "Login"
    end

    expect(page.status_code).to be(200)
  end
end

