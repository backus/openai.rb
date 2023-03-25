# frozen_string_literal: true

class OpenAI
  class API
    class Response
      include Concord.new(:internal_data)
      include AbstractType

      class MissingFieldError < StandardError
        include Anima.new(:path, :missing_key, :actual_payload)

        def message
          <<~ERROR
            Missing field #{missing_key.inspect} in response payload!
            Was attempting to access value at path `#{path}`.
            Payload: #{JSON.pretty_generate(actual_payload)}
          ERROR
        end
      end

      class << self
        private

        attr_accessor :field_registry
      end

      def self.register_field(field_name)
        self.field_registry ||= []
        field_registry << field_name
      end

      def self.from_json(raw_json)
        new(JSON.parse(raw_json, symbolize_names: true))
      end

      def initialize(internal_data)
        super(IceNine.deep_freeze(internal_data))
      end

      def self.field(name, path: [name], wrapper: nil)
        register_field(name)

        define_method(name) do
          field(path, wrapper: wrapper)
        end
      end

      def self.optional_field(name, path: name, wrapper: nil)
        register_field(name)

        define_method(name) do
          optional_field(path, wrapper: wrapper)
        end
      end

      def original_payload
        internal_data
      end

      def inspect
        attr_list = field_list.map do |field_name|
          "#{field_name}=#{__send__(field_name).inspect}"
        end.join(' ')
        "#<#{self.class} #{attr_list}>"
      end

      private

      # We need to access the registry list from the instance for `#inspect`.
      # It is just private in terms of the public API which is why we do this
      # weird private dispatch on our own class.
      def field_list
        self.class.__send__(:field_registry)
      end

      def optional_field(key_path, wrapper: nil)
        *head, tail = key_path

        parent = field(head)
        return unless parent.key?(tail)

        wrap_value(parent.fetch(tail), wrapper)
      end

      def field(key_path, wrapper: nil)
        value = key_path.reduce(internal_data) do |object, key|
          object.fetch(key) do
            raise MissingFieldError.new(
              path: key_path,
              missing_key: key,
              actual_payload: internal_data
            )
          end
        end

        wrap_value(value, wrapper)
      end

      def wrap_value(value, wrapper)
        return value unless wrapper

        if value.instance_of?(Array)
          value.map { |item| wrapper.new(item) }
        else
          wrapper.new(value)
        end
      end

      class Completion < Response
        class Choice < Response
          field :text
          field :index
          field :logprobs
          field :finish_reason
        end

        class Usage < Response
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

      class ChatCompletion < Response
        class Choice < Response
          class Message < Response
            field :role
            field :content
          end

          field :index
          field :message, wrapper: Message
          field :finish_reason
        end

        class Usage < Response
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

      class ChatCompletionChunk < Response
        class Delta < Response
          optional_field :role
          optional_field :_content, path: %i[content]

          def content
            _content.to_s
          end
        end

        class Choice < Response
          field :delta, wrapper: Delta
        end

        field :id
        field :object
        field :created
        field :model
        field :choices, wrapper: Choice
      end

      class Embedding < Response
        class EmbeddingData < Response
          field :object
          field :embedding
          field :index
        end

        class Usage < Response
          field :prompt_tokens
          field :total_tokens
        end

        field :object
        field :data, wrapper: EmbeddingData
        field :model
        field :usage, wrapper: Usage
      end

      class Model < Response
        field :id
        field :object
        field :owned_by
        field :permission
      end

      class Moderation < Response
        class Category < Response
          field :hate
          field :hate_threatening, path: %i[hate/threatening]
          field :self_harm, path: %i[self-harm]
          field :sexual
          field :sexual_minors, path: %i[sexual/minors]
          field :violence
          field :violence_graphic, path: %i[violence/graphic]
        end

        class CategoryScore < Response
          field :hate
          field :hate_threatening, path: %i[hate/threatening]
          field :self_harm, path: %i[self-harm]
          field :sexual
          field :sexual_minors, path: %i[sexual/minors]
          field :violence
          field :violence_graphic, path: %i[violence/graphic]
        end

        class Result < Response
          field :categories, wrapper: Category
          field :category_scores, wrapper: CategoryScore
          field :flagged
        end

        field :id
        field :model
        field :results, wrapper: Result
      end

      class ListModel < Response
        field :data, wrapper: Model
      end

      class Edit < Response
        class Choice < Response
          field :text
          field :index
        end

        class Usage < Response
          field :prompt_tokens
          field :completion_tokens
          field :total_tokens
        end

        field :object
        field :created
        field :choices, wrapper: Choice
        field :usage, wrapper: Usage
      end

      class ImageGeneration < Response
        class Image < Response
          field :url
        end

        field :created
        field :data, wrapper: Image
      end

      class ImageEdit < Response
        class ImageEditData < Response
          field :url
        end

        field :created
        field :data, wrapper: ImageEditData
      end

      class ImageVariation < Response
        class ImageVariationData < Response
          field :url
        end

        field :created
        field :data, wrapper: ImageVariationData
      end

      class File < Response
        field :id
        field :object
        field :bytes
        field :created_at
        field :filename
        field :purpose
        optional_field :deleted?, path: :deleted
      end

      class FileList < Response
        field :data, wrapper: File
        field :object
      end

      class FineTune < Response
        class Event < Response
          field :object
          field :created_at
          field :level
          field :message
        end

        class Hyperparams < Response
          field :batch_size
          field :learning_rate_multiplier
          field :n_epochs
          field :prompt_loss_weight
        end

        class File < Response
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

      class FineTuneList < Response
        field :object
        field :data, wrapper: FineTune
      end

      class FineTuneEventList < Response
        field :data, wrapper: FineTune::Event
        field :object
      end

      class Transcription < Response
        field :text
      end
    end
  end
end
