# frozen_string_literal: true

require 'concord'
require 'anima'
require 'http'
require 'addressable'

require 'openai/version'

class OpenAI
  include Concord.new(:api_key, :http)

  ResponseError = Class.new(StandardError)

  HOST = Addressable::URI.parse('https://api.openai.com/v1')

  def initialize(api_key, http: HTTP)
    super(api_key, http)
  end

  def create_completion(model:, **kwargs)
    Response::Completion.from_json(
      post('/v1/completions', model: model, **kwargs)
    )
  end

  def create_chat_completion(model:, messages:, **kwargs)
    Response::ChatCompletion.from_json(
      post('/v1/chat-completions', model: model, messages: messages, **kwargs)
    )
  end

  def inspect
    "#<#{self.class}>"
  end

  private

  def post(route, **body)
    url = HOST.join(route).to_str
    response = http_client.post(url, json: body)

    unless response.status.success?
      raise ResponseError, "Unexpected response #{response.status}\nBody:\n#{response.body}"
    end

    response.body.to_s
  end

  def http_client
    http.headers(
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{api_key}"
    )
  end

  class Response
    class JSONPayload
      include Concord.new(:data)

      def self.from_json(raw_json)
        new(JSON.parse(raw_json, symbolize_names: true))
      end

      def self.field(name, path: [name], wrapper: nil)
        define_method(name) do
          field(path, wrapper: wrapper)
        end
      end

      def self.optional_field(name, path: name)
        define_method(name) do
          optional_field(path)
        end
      end

      def original_payload
        data
      end

      private

      def optional_field(*key_path)
        *head, tail = key_path

        field(*head)[tail]
      end

      def field(key_path, wrapper: nil)
        value = key_path.reduce(data, :fetch)
        return value unless wrapper

        if value.is_a?(Array)
          value.map { |item| wrapper.new(item) }
        else
          wrapper.new(value)
        end
      end
    end

    class Completion < JSONPayload
      class Choice < JSONPayload
        field :text
        field :index
        field :logprobs
        field :finish_reason
      end

      class Usage < JSONPayload
        field :prompt_tokens
        field :completion_tokens
        field :total_tokens
      end

      field :id
      field :object
      field :created
      field :model
      field :choices, wrapper: Choice
      field :usage, wrapper: Usage
    end

    class ChatCompletion < JSONPayload
      class Choice < JSONPayload
        class Message < JSONPayload
          field :role
          field :content
        end

        field :index
        field :message, wrapper: Message
        field :finish_reason
      end

      class Usage < JSONPayload
        field :prompt_tokens
        field :completion_tokens
        field :total_tokens
      end

      field :id
      field :object
      field :created
      field :choices, wrapper: Choice
      field :usage, wrapper: Usage
    end
  end
end
