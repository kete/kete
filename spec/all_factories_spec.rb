require 'spec_helper'

def lint(name)
  fs = FactoryGirl.factories.select { |f| f.name == name }
  FactoryGirl.lint(fs)
end

shared_examples 'a working factory' do |name|
  describe "The #{name} factory" do
    it ":#{name} lints" do
      expect { lint(name) }.not_to raise_error
    end
    it ":#{name} is valid" do
      expect(FactoryGirl.build(name)).to be_valid
    end
    it ":#{name} can be saved" do
      expect(FactoryGirl.create(name)).to be_persisted
    end
  end
end

describe 'Factories' do
  it_behaves_like 'a working factory', :comment
  it_behaves_like 'a working factory', :basket
  it_behaves_like 'a working factory', :audio_recording
  it_behaves_like 'a working factory', :document
  it_behaves_like 'a working factory', :image_file
  it_behaves_like 'a working factory', :still_image
  it_behaves_like 'a working factory', :topic
  it_behaves_like 'a working factory', :topic_type
  it_behaves_like 'a working factory', :content_type
  it_behaves_like 'a working factory', :user
  it_behaves_like 'a working factory', :video
  it_behaves_like 'a working factory', :web_link

  describe ':web_link' do
    it 'building: has the expected default title' do
      wl = FactoryGirl.build :web_link
      expect(wl.title).to eq('Merube')
    end
    it 'create: has the expected default title' do
      wl = FactoryGirl.create :web_link
      expect(wl.title).to eq('Merube')
    end
    it 'build: sets explicit title as expected' do
      wl = FactoryGirl.build :web_link, title: 'foo'
      expect(wl.title).to eq('foo')
    end
    it 'create: sets explicit title as expected' do
      wl = FactoryGirl.create :web_link, title: 'foo'
      expect(wl.title).to eq('foo')
    end
  end

  describe ':topic' do
    it 'sets creator correctly' do
      user = FactoryGirl.create(:user)
      topic = FactoryGirl.create(:topic, creator: user)

      expect(topic.creator).to eq(user)
    end
  end
end
