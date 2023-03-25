# frozen_string_literal: true

require 'concord'
require 'anima'
require 'abstract_type'
require 'http'
require 'addressable'
require 'ice_nine'

require 'openai/api'
require 'openai/response'
require 'openai/version'

class OpenAI
  include Concord.new(:api_key, :http)

  class API
    class Error < StandardError
      include Concord::Public.new(:http_response)

      def message
        <<~ERROR
          Unexpected response status! Expected 2xx but got: #{http_response.status}

          Body:

          #{http_response.body}
        ERROR
      end
    end
  end

  HOST = Addressable::URI.parse('https://api.openai.com/v1')

  def initialize(api_key, http: HTTP)
    super(api_key, http)
  end

  def completions
    API::Completion.new(self)
  end

  def chat_completions
    API::ChatCompletion.new(self)
  end

  def embeddings
    API::Embedding.new(self)
  end

  def models
    API::Model.new(self)
  end

  def edits
    API::Edit.new(self)
  end

  def files
    API::File.new(self)
  end

  def fine_tunes
    API::FineTune.new(self)
  end

  def images
    API::Image.new(self)
  end

  def audio
    API::Audio.new(self)
  end

  def moderations
    API::Moderation.new(self)
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
