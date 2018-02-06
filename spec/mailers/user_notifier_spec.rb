require 'spec_helper'

describe UserNotifier do
  it 'does not blow up when you initialize it' do
    described_class.generic_view_paths # RABID: just hitting a 0 arg method that I know exists to prove that this mailer loads ok
  end
end
