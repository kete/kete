# frozen_string_literal: true

# see has_value.rb for context
#
# structure of method name is simply to use test_file_name (sans _test)
# as beginning of method name
# and something unique within that test file for the end of method name
# probably something descriptiive
#
# Important Note: if you have substitution within a string
# to have it properly work, wrap it in escaped double quotes
# e.g. HasValue.something = "\"blah blah #{blah}, yada yada yada\""
HasValue.oai_dc_helpers_title_xml = "<dc:title>Item</dc:title>"
HasValue.oai_dc_helpers_title_with_lang_xml = "\"<dc:title xml:lang=\"\#\{I18n.default_locale\}\"\>Item\</dc:title>\""
HasValue.oai_dc_helpers_description_xml = "<dc:description><![CDATA[Description]]></dc:description>"
HasValue.oai_dc_helpers_description_xml_when_only_xml = "<dc:description><![CDATA[Description]]></dc:description>"
HasValue.oai_dc_helpers_short_summary_xml_when_only_xml = "<dc:description><![CDATA[Short Summary]]></dc:description>"
HasValue.oai_dc_helpers_tags_xml = "<dc:subject><![CDATA[tag]]></dc:subject>"
HasValue.oai_dc_helpers_extended_content_xml = "<dc:description>some text</dc:description>"
