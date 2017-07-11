Time::DATE_FORMATS.merge!(
  natural: lambda { |time| time.strftime("%B #{time.day.ordinalize}, %Y at %l:%M %p") },
  natural_short: lambda { |time| time.strftime("%b #{time.day.ordinalize}, %Y at %l:%M %p") }
)
