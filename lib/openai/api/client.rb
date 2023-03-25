# frozen_string_literal: true

class OpenAI
  class API
    class Client
      include Concord.new(:api_key, :http)

      HOST = Addressable::URI.parse('https://api.openai.com/v1')

      def initialize(api_key, http: HTTP)
        super(api_key, http)
      end

      def inspect
        "#<#{self.class}>"
      end

      def get(route)
        unwrap_response(json_http_client.get(url_for(route)))
      end

      def delete(route)
        unwrap_response(json_http_client.delete(url_for(route)))
      end

      def post(route, **body)
        unwrap_response(json_http_client.post(url_for(route), json: body))
      end

      def post_form_multipart(route, **body)
        unwrap_response(http_client.post(url_for(route), form: body))
      end

      private

      def url_for(route)
        HOST.join(route).to_str
      end

      def unwrap_response(response)
        raise API::Error, response unless response.status.success?

        response.body.to_str
      end

      def json_http_client
        http_client.headers('Content-Type' => 'application/json')
      end

      def http_client
        http.headers('Authorization' => "Bearer #{api_key}")
      end
    end
  end
end
