# frozen_string_literal: true

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

def pdf_doc_file_path
  Rails.root.join('spec', 'fixtures', 'document_example.pdf').to_s
end

def ms_word_doc_file_path
  Rails.root.join('spec', 'fixtures', 'document_example.docx').to_s
end

##
# id must be the id attribute of the editor instance (without the #) e.g.
#     <textarea id="foo" ...></textarea>
# would be filled in by calling
#     tinymce_fill_in 'foo', 'some stuff'
#
def tinymce_fill_in(id, val)
  # wait until the TinyMCE editor instance is ready. This is required for cases
  # where the editor is loaded via XHR.
  sleep 0.5 until page.evaluate_script("tinyMCE.get('#{id}') !== null")

  js = "tinyMCE.get('#{id}').setContent('#{val}')"
  page.execute_script(js)
end
