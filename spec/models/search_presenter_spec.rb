# frozen_string_literal: true

require 'spec_helper'

describe SearchPresenter do
  it 'is not broken' do
    q = SearchQuery.new(
      search_terms: 'maori',
      date_since: '',
      date_until: '',
      privacy_type: '',
      controller_name_for_zoom_class: '',
      topic_type: '',
      target_basket: '',
      page: '1'
    )
    sp = SearchPresenter.new(query: q)
  end
end
