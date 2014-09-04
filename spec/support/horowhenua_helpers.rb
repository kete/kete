def username
  "eoinkelly"
end

def password
  "iDHVrBKH2QeH"
end

def sign_in
  visit "/"
  within(".user-nav") do
    click_link('Login')
  end

  within("form#login") do
    fill_in "Login", with: username
    fill_in "Password", with: password
    click_button "Login"
  end
end

def sample_image_path
  Rails.root.join('spec', 'fixtures', 'sample.jpg').to_s
end
