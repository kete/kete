class SearchSource < ActiveRecord::Base
  acts_as_list

  validates_presence_of :title
  validates_presence_of :source_type
  validates_presence_of :base_url
  validates_presence_of :limit
  validates_presence_of :cache_interval

  cattr_accessor :acceptable_source_types
  @@acceptable_source_types = %w{ feed }

  def title_id
    title.gsub(/\W/, '_').downcase
  end

  def authorized_for?(args)
    case args[:action].to_sym
    when :move_higher
      !first?
    when :move_lower
      !last?
    else
      true
    end
  end

end
