# frozen_string_literal: true

# Workaround for: [CVE-2015-3226] XSS Vulnerability in ActiveSupport::JSON.encode
module ActiveSupport
  module JSON
    module Encoding
      private

      class EscapedString
        def to_s
          self
        end
      end
    end
  end
end
