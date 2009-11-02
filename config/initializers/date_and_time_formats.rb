ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :natural => lambda { |time| time.strftime("%B #{time.day.ordinalize}, %Y at %I:%M %p") }
)
