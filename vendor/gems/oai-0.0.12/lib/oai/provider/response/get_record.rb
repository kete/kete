module OAI::Provider::Response
  class GetRecord < RecordResponse
    required_parameters :identifier

    def to_xml
      id = extract_identifier(options.delete(:identifier))
      unless record = provider.model.find(id, options)
        raise OAI::IdException.new
      end

      response do |r|
        r.GetRecord do
          header_and_data_for(record, r)
        end
      end
    end
  end
end
