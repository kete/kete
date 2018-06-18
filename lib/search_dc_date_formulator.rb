# frozen_string_literal: true

module SearchDcDateFormulator
  unless included_modules.include? SearchDcDateFormulator

    def dc_date_display_of(dc_dates)
      return '' unless SystemSetting.dc_date_display_on_search_results?
      content_tag(:div, select_and_format_dc_dates_from(dc_dates), class: 'generic-result-dc-dates')
    end

    def dc_date_separator; ', '; end

    def select_and_format_dc_dates_from(dc_dates)
      # The dates are strings containing a UTC timestamp
      # We want these to be Time objects
      dc_dates = dc_dates.collect { |date| date.to_time rescue date }
      # run the dc dates through each formulator if present
      SystemSetting.dc_date_display_formulator.split(',').each do |formulator|
        dc_dates = send(formulator.strip.to_sym, dc_dates)
      end
      # collect all the dc dates and format any that haven't been yet, then join with the dc_date_separator
      dc_dates.collect { |d| format_date_from(d) }.join(dc_date_separator)
    end

    def format_date_from(dc_date)
      # if it's anything else, assume it's been formatted by another formulator
      return dc_date unless [Time, DateTime].include?(dc_date.class)
      # convert it to local time if the method is available (not available on dates < 1900)
      dc_date = dc_date.localtime if dc_date.respond_to?(:localtime)
      date_bits = []
      I18n.t('date.order').each do |order|
        case order
        when :year
          date_bits << dc_date.year if SystemSetting.dc_date_display_detail_level.include?('year')
        when :month
          date_bits << dc_date.strftime('%m') if SystemSetting.dc_date_display_detail_level.include?('month')
        when :day
          date_bits << dc_date.strftime('%d') if SystemSetting.dc_date_display_detail_level.include?('day')
        end
      end
      date_bits.join('-')
    end

    def resolve_to_circa_if_present(dc_dates)
      dates = []
      while dc_dates.size > 0 do
        date = dc_dates.shift
        # if we have a circa date, 2 dc:dates are added. One 5 years before, one 5 years after, and the
        # date in the middle. Including the year itself, from the first date, there is 10 years in total
        # So if the next dc:date is 10 years away, and the one after that 5 years, we are dealing with a circa
        # Rescue false incase any of the three dates doesn't respond to #year (like a string)
        if ((dc_dates.size >= 2 && (date + 10.years).year == dc_dates[0].year && (date + 5.years).year == dc_dates[1].year) rescue false)
          dates << "c.#{format_date_from(dc_dates[1])}" # the last one is the circa date
          2.times { dc_dates.shift } # remove the dates 10 & 5 years ahead (convered in circa)
        else
          dates << date
        end
      end
      dates
    end

    def format_to_locales_specification(dc_dates)
      dates = []
      while dc_dates.size > 0 do
        date = dc_dates.shift
        if [Time, DateTime].include?(date.class)
          dates << date.localtime.to_s(:long)
        else
          dates << date
        end
      end
      dates
    end

  end
end
