# frozen_string_literal: true

Time::DATE_FORMATS[:natural] = lambda { |time| time.strftime("%B #{time.day.ordinalize}, %Y at %l:%M %p") }
Time::DATE_FORMATS[:natural_short] = lambda { |time| time.strftime("%b #{time.day.ordinalize}, %Y at %l:%M %p") }
