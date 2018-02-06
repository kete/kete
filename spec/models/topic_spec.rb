require 'spec_helper'

describe Topic do
  it 'does not blow up when you initialize it' do
    expect { described_class.new }.not_to raise_error
  end

  it 'allows setting of a custom title' do
    unique = 'a unique title'
    topic_type = FactoryGirl.create(:topic_type)
    basket = FactoryGirl.create(:basket)
    topic = described_class.new(title: unique, topic_type: topic_type, basket: basket)
    topic.save!
    expect(topic.title).to eq(unique)
  end

  describe 'creator (user who created the topic)' do
    let(:topic_type) { FactoryGirl.create(:topic_type) }
    let(:basket) { FactoryGirl.create(:basket) }
    let(:user) { FactoryGirl.create(:user) }

    it 'cannot be set during topic creation' do
      expect {
        described_class.create(title: 'A title',
                     topic_type: topic_type,
                     basket: basket,
                     creator: user)
      }.to raise_error
    end

    it 'can be set after a Topic is created' do
      topic = described_class.create(title: 'A title',
                           topic_type: topic_type,
                           basket: basket)

      topic.creator = user
      expect(topic.creator).to eq(user)
    end
  end
end
