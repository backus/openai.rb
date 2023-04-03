# frozen_string_literal: true

class OpenAI
  class API
    class Client
      include Concord.new(:api_key, :organization_id, :http)

      public :api_key

      HOST = Addressable::URI.parse('https://api.openai.com/v1')

      def initialize(api_key, organization_id: nil, http: HTTP)
        super(api_key, organization_id, http)
      end

      def inspect
        "#<#{self.class} organization_id=#{organization_id.inspect}>"
      end

      def get(route)
        unwrap_response(json_http_client.get(url_for(route)))
      end

      def delete(route)
        unwrap_response(json_http_client.delete(url_for(route)))
      end

      def post(route, **body)
        url = url_for(route)
        if block_given?
          json_http_client.persistent(url) do |connection|
            response = connection.post(url, json: body)

            # Data comes in as JSON frames like so:
            #
            #   data: {"choices": [{"text": "He"}]}
            #   data: {"choices": [{"text": "llo, "}]}
            #   data: {"choices": [{"text": "Wor"}]}
            #   data: {"choices": [{"text": "ld!"}]}
            #   data: [DONE]
            #
            # (The actual frames are fully formed JSON objects just like a
            # non-streamed response, the examples above are just for brevity)
            response.body.each do |chunk|
              chunk.split("\n\n").each do |part|
                frame = part.delete_prefix('data: ').strip

                yield(frame) unless frame == '[DONE]' || frame.empty?
              end
            end
          end

          # Return nil since we aren't reconstructing what the API would have
          # returned if we had not streamed the response
          nil
        else
          unwrap_response(json_http_client.post(url, json: body))
        end
      end

      def post_form_multipart(route, **body)
        unwrap_response(http_client.post(url_for(route), form: body))
      end

      private

      def url_for(route)
        HOST.join(route).to_str
      end

      def unwrap_response(response)
        raise API::Error.parse(response) unless response.status.success?

        response.body.to_str
      end

      def json_http_client
        http_client.headers('Content-Type' => 'application/json')
      end

      def http_client
        headers = { 'Authorization' => "Bearer #{api_key}" }
        headers['OpenAI-Organization'] = organization_id if organization_id
        http.headers(headers)
      end
    end
  end
end
