# frozen_string_literal: true

require 'concord'
require 'anima'
require 'abstract_type'
require 'http'
require 'addressable'

require 'openai/api'
require 'openai/version'

class OpenAI
  class API
    include Concord.new(:client)
    include AbstractType

    class Completion < self
      def create(model:, **kwargs)
        Response::Completion.from_json(
          client.post('/v1/completions', model: model, **kwargs)
        )
      end
    end

    class ChatCompletion < self
      def create(model:, messages:, **kwargs)
        Response::ChatCompletion.from_json(
          client.post('/v1/chat/completions', model: model, messages: messages, **kwargs)
        )
      end
    end

    class Embedding < self
      def create(model:, input:, **kwargs)
        Response::Embedding.from_json(
          client.post('/v1/embeddings', model: model, input: input, **kwargs)
        )
      end
    end

    class Model < self
      def list
        Response::ListModel.from_json(client.get('/v1/models'))
      end

      def get(model_id)
        Response::Model.from_json(
          client.get("/v1/models/#{model_id}")
        )
      end
    end

    class Edit < self
      def create(model:, instruction:, **kwargs)
        Response::Edit.from_json(
          client.post('/v1/edits', model: model, instruction: instruction, **kwargs)
        )
      end
    end

    class File < self
      def create(file:, purpose:)
        absolute_path = Pathname.new(file).expand_path.to_s
        form_file = HTTP::FormData::File.new(absolute_path)
        Response::File.from_json(
          client.post_form_multipart('/v1/files', file: form_file, purpose: purpose)
        )
      end

      def list
        Response::FileList.from_json(
          client.get('/v1/files')
        )
      end

      def delete(file_id)
        Response::File.from_json(
          client.delete("/v1/files/#{file_id}")
        )
      end

      def get(file_id)
        Response::File.from_json(
          client.get("/v1/files/#{file_id}")
        )
      end

      def get_content(file_id)
        client.get("/v1/files/#{file_id}/content")
      end
    end

    class FineTune < self
      def list
        Response::FineTuneList.from_json(
          client.get('/v1/fine-tunes')
        )
      end

      def create(training_file:, **kwargs)
        Response::FineTune.from_json(
          client.post('/v1/fine-tunes', training_file: training_file, **kwargs)
        )
      end

      def get(fine_tune_id)
        Response::FineTune.from_json(
          client.get("/v1/fine-tunes/#{fine_tune_id}")
        )
      end

      def cancel(fine_tune_id)
        Response::FineTune.from_json(
          client.post("/v1/fine-tunes/#{fine_tune_id}/cancel")
        )
      end
    end

    class Image < self
      def create(prompt:, **kwargs)
        Response::ImageGeneration.from_json(
          client.post('/v1/images/generations', prompt: prompt, **kwargs)
        )
      end
    end
  end
end
