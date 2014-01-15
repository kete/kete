require 'spec_helper'

describe Topic do
  it "does not blow up when you initialize it" do
    expect { Topic.new }.to_not raise_error
  end

  it "gets a default title of 'blank title' if none specified" do
    load_production_seeds
    topic = FactoryGirl.create(:topic)
    expect(topic.title).to eq('blank title')
  end

  it "allows setting of a custom title" do
    load_production_seeds
    unique = "a unique title"
    topic = Topic.new(title: unique, topic_type: TopicType.last, basket: Basket.last)
    topic.save!
    expect(topic.title).to eq(unique)
  end

end 
