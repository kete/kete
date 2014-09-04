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

def audio_file_path
  Rails.root.join('spec', 'fixtures', 'audio_example.mp3').to_s
end

def video_file_path
  Rails.root.join('spec', 'fixtures', 'video_example.mp4').to_s
end
