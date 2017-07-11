# -*- coding: utf-8 -*-
module LatitudeLongitudeConvertors
  unless included_modules.include? LatitudeLongitudeConvertors

    # used in converting DMS latlng to Decimal latng format compatible with Google maps
    # takes the following formats
    #    S41°17'31.80", E174°46'46.20"
    #    41 deg 17' 31.80" S, 174 deg 46' 46.20" E
    def convert_dms_to_decimal_degree(dms_string)
      dms_raw_array = dms_string.is_a?(Array) ? dms_string : dms_string.split(',')
      dms_parts = dms_raw_array.collect do |dms|
        sign = dms.scan(/[NE]/).size > 0 ? '+' : '-'
        parts = dms.gsub(/[^\d.]/, ' ').split(' ').collect { |part| part.to_f }
        sign + (parts[0].to_f + ((parts[1].to_f * 60 + parts[2].to_f) / 3600.0)).to_s
      end
      { latitude: dms_parts[0].to_f, longitude: dms_parts[1].to_f }
    end

  end
end
