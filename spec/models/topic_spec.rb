require 'spec_helper'

describe Topic do
  it "does not blow up when you initialize it" do
    expect { Topic.new }.to_not raise_error
  end

  it "allows setting of a custom title" do
    unique = "a unique title"
    topic_type = FactoryGirl.create(:topic_type)
    basket = FactoryGirl.create(:basket)
    topic = Topic.new(title: unique, topic_type: topic_type, basket: basket)
    topic.save!
    expect(topic.title).to eq(unique)
  end
end
