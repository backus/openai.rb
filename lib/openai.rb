# frozen_string_literal: true

require 'concord'
require 'anima'
require 'abstract_type'
require 'http'
require 'addressable'

require 'openai/api'
require 'openai/version'

class OpenAI
  include Concord.new(:api_key, :http)

  ResponseError = Class.new(StandardError)

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
    unless response.status.success?
      raise ResponseError, "Unexpected response #{response.status}\nBody:\n#{response.body}"
    end

    response.body.to_s
  end

  def json_http_client
    http_client.headers('Content-Type' => 'application/json')
  end

  def http_client
    http.headers('Authorization' => "Bearer #{api_key}")
  end

  class Response
    class JSONPayload
      include Concord.new(:internal_data)

      def self.from_json(raw_json)
        new(JSON.parse(raw_json, symbolize_names: true))
      end

      def self.field(name, path: [name], wrapper: nil)
        given_wrapper = wrapper
        define_method(name) do
          field(path, wrapper: given_wrapper)
        end
      end

      def self.optional_field(name, path: name)
        define_method(name) do
          optional_field(path)
        end
      end

      def original_payload
        internal_data
      end

      private

      def optional_field(key_path)
        *head, tail = key_path

        field(head)[tail]
      end

      def field(key_path, wrapper: nil)
        value = key_path.reduce(internal_data, :fetch)
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

    class Embedding < JSONPayload
      class EmbeddingData < JSONPayload
        field :object
        field :embedding
        field :index
      end

      class Usage < JSONPayload
        field :prompt_tokens
        field :total_tokens
      end

      field :object
      field :data, wrapper: EmbeddingData
      field :model
      field :usage, wrapper: Usage
    end

    class Model < JSONPayload
      field :id
      field :object
      field :owned_by
      field :permission
    end

    class ListModel < JSONPayload
      field :data, wrapper: Model
    end

    class Edit < JSONPayload
      class Choice < JSONPayload
        field :text
        field :index
      end

      class Usage < JSONPayload
        field :prompt_tokens
        field :completion_tokens
        field :total_tokens
      end

      field :object
      field :created
      field :choices, wrapper: Choice
      field :usage, wrapper: Usage
    end

    class ImageGeneration < JSONPayload
      class Image < JSONPayload
        field :url
      end

      field :created
      field :data, wrapper: Image
    end

    class ImageEdit < JSONPayload
      class ImageEditData < JSONPayload
        field :url
      end

      field :created
      field :data, wrapper: ImageEditData
    end

    class ImageVariation < JSONPayload
      class ImageVariationData < JSONPayload
        field :url
      end

      field :created
      field :data, wrapper: ImageVariationData
    end

    class File < JSONPayload
      field :id
      field :object
      field :bytes
      field :created_at
      field :filename
      field :purpose
      optional_field :deleted?, path: :deleted
    end

    class FileList < JSONPayload
      field :data, wrapper: File
      field :object
    end

    class FineTune < JSONPayload
      class Event < JSONPayload
        field :object
        field :created_at
        field :level
        field :message
      end

      class Hyperparams < JSONPayload
        field :batch_size
        field :learning_rate_multiplier
        field :n_epochs
        field :prompt_loss_weight
      end

      class File < JSONPayload
        field :id
        field :object
        field :bytes
        field :created_at
        field :filename
        field :purpose
      end

      field :id
      field :object
      field :model
      field :created_at
      field :events, wrapper: Event
      field :fine_tuned_model
      field :hyperparams, wrapper: Hyperparams
      field :organization_id
      field :result_files, wrapper: File
      field :status
      field :validation_files, wrapper: File
      field :training_files, wrapper: File
      field :updated_at
    end

    class FineTuneList < JSONPayload
      field :object
      field :data, wrapper: FineTune
    end

    class FineTuneEventList < JSONPayload
      field :data, wrapper: FineTune::Event
      field :object
    end

    class Transcription < JSONPayload
      field :text
    end
  end
end
