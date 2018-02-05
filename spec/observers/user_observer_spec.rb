require 'spec_helper'

describe UserObserver do
  it 'does not blow up when you initialize it' do
    # Observers are singletons so we cannot use #new
    # * Observers provide the #instance method that instantiates & registers it
    # * See http://api.rubyonrails.org/v3.2.13/classes/ActiveRecord/Observer.html
    foo = described_class.instance
  end
end
