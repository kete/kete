require 'spec_helper'

include ActionDispatch::TestProcess # module that provides #fixture_file_upload

describe ImageFile do
  it 'does not blow up when you initialize it' do
    ImageFile.new
  end

  it 'can be created while referencing a file on disk' do
    path = Rails.root.join('spec', 'fixtures', 'sample.jpg').to_s
    mimetype = 'image/jpeg'

    ff = fixture_file_upload(path, mimetype)

    image_file = ImageFile.new(uploaded_data: ff)
    expect(image_file).to be_valid

    image_file.save!
    expect(image_file).to be_persisted
  end
end
