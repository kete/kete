# frozen_string_literal: true

require 'spec_helper'

describe SystemSetting do
  it 'does not blow up when you initialize it' do
    foo = SystemSetting.new
  end
end
