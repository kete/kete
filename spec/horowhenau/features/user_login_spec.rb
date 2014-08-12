require 'spec_helper'

feature "User login" do

  def sign_in
    visit "/"
    within(".user-nav") do
      click_link('Login')
    end

    within("form#login") do
      fill_in "Login", with: "eoinkelly"
      fill_in "Password", with: "iDHVrBKH2QeH"
      click_button "Login"
    end
  end

  it "login flow works" do
    sign_in
    expect(page.status_code).to be(200)
    expect(page).to have_text("Logged in successfully")
  end

  it "logout works" do
    sign_in
    click_link "Logout"
    expect(page.status_code).to be(200)
    expect(page).to have_text("You have been logged out.")
  end
end

