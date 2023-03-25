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
      post('/v1/chat/completions', model: model, messages: messages, **kwargs)
    )
  end

  def create_embedding(model:, input:, **kwargs)
    Response::Embedding.from_json(
      post('/v1/embeddings', model: model, input: input, **kwargs)
    )
  end

  def list_models
    Response::ListModel.from_json(get('/v1/models'))
  end

  def get_model(model_id)
    Response::Model.from_json(
      get("/v1/models/#{model_id}")
    )
  end

  def create_edit(model:, instruction:, **kwargs)
    Response::Edit.from_json(
      post('/v1/edits', model: model, instruction: instruction, **kwargs)
    )
  end

  def create_image_generation(prompt:, **kwargs)
    Response::ImageGeneration.from_json(
      post('/v1/images/generations', prompt: prompt, **kwargs)
    )
  end

  def create_file(file:, purpose:)
    absolute_path = Pathname.new(file).expand_path.to_s
    form_file = HTTP::FormData::File.new(absolute_path)
    Response::File.from_json(
      post_form_multipart('/v1/files', file: form_file, purpose: purpose)
    )
  end

  def list_files
    Response::FileList.from_json(
      get('/v1/files')
    )
  end

  def delete_file(file_id)
    Response::File.from_json(
      delete("/v1/files/#{file_id}")
    )
  end

  def get_file(file_id)
    Response::File.from_json(
      get("/v1/files/#{file_id}")
    )
  end

  def get_file_content(file_id)
    get("/v1/files/#{file_id}/content")
  end

  def list_fine_tunes
    Response::FineTuneList.from_json(
      get('/v1/fine-tunes')
    )
  end

  def create_fine_tune(training_file:, **kwargs)
    Response::FineTune.from_json(
      post('/v1/fine-tunes', training_file: training_file, **kwargs)
    )
  end

  def get_fine_tune(fine_tune_id)
    Response::FineTune.from_json(
      get("/v1/fine-tunes/#{fine_tune_id}")
    )
  end

  def cancel_fine_tune(fine_tune_id)
    Response::FineTune.from_json(
      post("/v1/fine-tunes/#{fine_tune_id}/cancel")
    )
  end

  def transcribe_audio(file:, model:, **kwargs)
    absolute_path = Pathname.new(file).expand_path.to_s
    form_file = HTTP::FormData::File.new(absolute_path)
    Response::Transcription.from_json(
      post_form_multipart(
        '/v1/audio/transcriptions',
        file: form_file,
        model: model,
        **kwargs
      )
    )
  end

  def inspect
    "#<#{self.class}>"
  end

  private

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

    class Transcription < JSONPayload
      field :text
    end
  end
end
