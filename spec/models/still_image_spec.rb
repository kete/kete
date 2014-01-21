require 'spec_helper'

describe StillImage do
  let(:still_image) { StillImage.new }

  it "does not blow up when you initialize it" do
    still_image
  end

  it "can be validated" do
    expect( factorygirl.build(:validatable_still_image) ).to be_valid

    # rob:  not savable because of basket (see note in factory).
    expect { factorygirl.create(:validateable_still_image) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( factorygirl.create(:savable_still_image) ).to be_a(StillImage)
  end

  it "can be saved to the database with minimal data filled in" do
    still_image_attrs = {
      title: "Fur Seal",
          # NOTE:  title IS SAVED AS "blank title" for some reason
          #        but can be correctly set with si.title = "Merube" 
          #        after it is saved.
      #description: "Has a cap and a chain.",
      basket_id: 1,
    }
    still_image = StillImage.new(still_image_attrs)

    expect(still_image).to be_valid
    expect { still_image.save! }.to_not raise_error

    image_file_attrs = {
      #parent_id: nil,
      #thumbnail: nil,
      filename: "furry.JPG",
      content_type: "image/jpeg",
      size: rand(10000000),

        # NOTE: these are verified, just not in the SQL.
      still_image_id: si.id,
      width: rand(10000000),
      height: rand(10000000),
    }
    image_file = ImageFile.new(image_file_attrs)

    expect(image_file).to be_valid
    expect { image_file.save! }.to_not raise_error

    #make_thumbnails(image_file)
  end
end


def make_thumbnails(ifi)
   if1 = ifi.clone
   if1.parent_id = 1
   if1.thumbnail = "medium"
   if1.filename = "furry_medium.JPG"
   if1.save
       
   if2 = ifi.clone
   if2.parent_id = 1
   if2.thumbnail = "large"
   if2.filename = "furry_large.JPG"
   if2.save
    
   if3 = ifi.clone
   if3.parent_id = 1
   if3.thumbnail = "small"
   if3.filename = "furry_small.JPG"
   if3.save
    

   if4 = ifi.clone
   if4.parent_id = 1
   if4.thumbnail = "small_sq"
   if4.filename = "furry_small_sq.JPG"
   if4.save
end

