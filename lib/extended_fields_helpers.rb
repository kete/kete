# frozen_string_literal: true

module ExtendedFieldsHelpers
  unless included_modules.include? ExtendedFieldsHelpers
    # move any problematic punctuation that will mess up our xml
    # element name to html entities
    # currently for \,/,&,',",comma,<,>
    # allowed: .,_,-
    # should handle the case where & is a part of an entity already
    # and not escape it
    def encode_problematic_punctuation_to_entities(string)
      string.to_s.gsub(/&(?![\#\d\w]+;)/, '&amp;').gsub(/\"/, '&quot;').gsub(/>/, '&gt;').gsub(/</, '&lt;').gsub(/\'/, '&#39;').gsub(/\//, '&#47;').gsub(/\\/, '&#92;').gsub(/,/, '&#44;')
    end

    def decode_problematic_punctuation_to_entities(string)
      string.to_s.gsub(/&quot;/, '"').gsub(/&gt;/, '>').gsub(/&lt;/, '<').gsub(/&#39;/, "\'").gsub(/&#47;/, '/').gsub(/&#92;/, '\\').gsub(/&#44;/, ',').gsub(/&amp;/, '&')
    end
  end
end
