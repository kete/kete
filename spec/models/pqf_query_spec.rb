# frozen_string_literal: true

require 'spec_helper'

describe PqfQuery do
  it 'does not blow up when you initialize it' do
    foo = PqfQuery.new
  end
end
