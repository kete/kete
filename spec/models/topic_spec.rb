require 'spec_helper'

describe Topic do
  it "does not blow up when you initialize it" do
    expect { Topic.new }.to_not raise_error
  end

  it "allows setting of a custom title" do
    unique = "a unique title"
    topic = Topic.new(title: unique, topic_type: TopicType.last, basket: Basket.last)
    topic.save!
    expect(topic.title).to eq(unique)
  end

end
