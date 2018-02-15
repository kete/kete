require 'spec_helper'

def first_result
  find('.generic-result-wrapper', match: :first)
end

def first_result_text
  first_result.find(".generic-result-header")
end

def first_image
  find('.image-result-wrapper', match: :first)
end

def first_image_text
  first_image.find(".image-result-header")
end

def within_contributor_area
  find("#content-tools")
end

describe "Contributed By Searching" do
  it "Searching by contributions from a topic page" do
    visit "/en/site/topics/196-levin-pottery-club"
    within_contributor_area.click_link "Rosalie"

    expect(page).to have_content "Topics (83)"
    expect(first_result_text).to have_content "The Petersen Estate"

    click_on "Images (258)"
    expect(first_image_text).to have_content "Dame Silvia Cartwright unveiling the Icon"

    click_on "Audio (1)"
    expect(first_result_text).to have_content "Horowhenua song"

    click_on "Video (1)"
    expect(first_result_text).to have_content "Intro to Kete Horowhenua"

    click_on "Web links (1)"
    expect(first_result_text).to have_content "http://www.anzac.govt.nz/"

    click_on "Documents (4)"
    expect(first_result_text).to have_content "June Gillies"
  end
end
