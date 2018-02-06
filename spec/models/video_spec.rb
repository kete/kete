require 'spec_helper'

describe Video do
  let(:video) { described_class.new }

  it 'does not blow up when you initialize it' do
    video
  end

  describe 'item privacy' do
    describe '(versioned overload) how it interacts with versioning' do
      describe 'instance methods (added to instance of this model class' do
        it 'public methods' do
          expect(video).to respond_to(:private_version!)
          expect(video).to respond_to(:public_version!)
          expect(video).to respond_to(:has_public_version?)
          expect(video).to respond_to(:has_private_version?)
          expect(video).to respond_to(:latest_version_is_private?)
          expect(video).to respond_to(:is_private?)
          expect(video).to respond_to(:private_version)
          expect(video).to respond_to(:save_without_saving_private!)
        end
      end

      describe 'instance methods (added to instance of this model class' do
        it 'class methods' do
          expect(described_class).to respond_to(:without_saving_private)
        end
      end
    end
  end
end
