# frozen_string_literal: true

class OpenAI
  class API
    class Resource
      include Concord.new(:client)
      include AbstractType

      private

      def post(...)
        client.post(...)
      end

      def post_form_multipart(...)
        client.post_form_multipart(...)
      end

      def get(...)
        client.get(...)
      end

      def form_file(path)
        absolute_path = Pathname.new(path).expand_path.to_s
        HTTP::FormData::File.new(absolute_path)
      end
    end

    class Completion < Resource
      def create(model:, stream: false, **kwargs)
        if stream && !block_given?
          raise 'Streaming responses require a block'
        elsif !stream && block_given?
          raise 'Non-streaming responses do not support a block'
        end

        if stream
          post('/v1/completions', model: model, stream: stream, **kwargs) do |chunk|
            yield(Response::Completion.from_json(chunk))
          end

          nil
        else
          Response::Completion.from_json(
            post('/v1/completions', model: model, **kwargs)
          )
        end
      end
    end

    class ChatCompletion < Resource
      def create(model:, messages:, **kwargs)
        Response::ChatCompletion.from_json(
          post('/v1/chat/completions', model: model, messages: messages, **kwargs)
        )
      end
    end

    class Embedding < Resource
      def create(model:, input:, **kwargs)
        Response::Embedding.from_json(
          post('/v1/embeddings', model: model, input: input, **kwargs)
        )
      end
    end

    class Model < Resource
      def list
        Response::ListModel.from_json(get('/v1/models'))
      end

      def fetch(model_id)
        Response::Model.from_json(
          get("/v1/models/#{model_id}")
        )
      end
    end

    class Moderation < Resource
      def create(input:, model:)
        Response::Moderation.from_json(
          post('/v1/moderations', input: input, model: model)
        )
      end
    end

    class Edit < Resource
      def create(model:, instruction:, **kwargs)
        Response::Edit.from_json(
          post('/v1/edits', model: model, instruction: instruction, **kwargs)
        )
      end
    end

    class File < Resource
      def create(file:, purpose:)
        Response::File.from_json(
          post_form_multipart('/v1/files', file: form_file(file), purpose: purpose)
        )
      end

      def list
        Response::FileList.from_json(
          get('/v1/files')
        )
      end

      def delete(file_id)
        Response::File.from_json(
          client.delete("/v1/files/#{file_id}")
        )
      end

      def fetch(file_id)
        Response::File.from_json(
          get("/v1/files/#{file_id}")
        )
      end

      def get_content(file_id)
        get("/v1/files/#{file_id}/content")
      end
    end

    class FineTune < Resource
      def list
        Response::FineTuneList.from_json(
          get('/v1/fine-tunes')
        )
      end

      def create(training_file:, **kwargs)
        Response::FineTune.from_json(
          post('/v1/fine-tunes', training_file: training_file, **kwargs)
        )
      end

      def fetch(fine_tune_id)
        Response::FineTune.from_json(
          get("/v1/fine-tunes/#{fine_tune_id}")
        )
      end

      def cancel(fine_tune_id)
        Response::FineTune.from_json(
          post("/v1/fine-tunes/#{fine_tune_id}/cancel")
        )
      end

      def list_events(fine_tune_id)
        Response::FineTuneEventList.from_json(
          get("/v1/fine-tunes/#{fine_tune_id}/events")
        )
      end
    end

    class Image < Resource
      def create(prompt:, **kwargs)
        Response::ImageGeneration.from_json(
          post('/v1/images/generations', prompt: prompt, **kwargs)
        )
      end

      def create_variation(image:, **kwargs)
        Response::ImageVariation.from_json(
          post_form_multipart('/v1/images/variations', {
                                image: form_file(image),
                                **kwargs
                              })
        )
      end

      def edit(image:, prompt:, mask: nil, **kwargs)
        params = {
          image: form_file(image),
          prompt: prompt,
          **kwargs
        }

        params[:mask] = form_file(mask) if mask

        Response::ImageEdit.from_json(
          post_form_multipart('/v1/images/edits', **params)
        )
      end
    end

    class Audio < Resource
      def transcribe(file:, model:, **kwargs)
        Response::Transcription.from_json(
          post_form_multipart(
            '/v1/audio/transcriptions',
            file: form_file(file),
            model: model,
            **kwargs
          )
        )
      end

      def translate(file:, model:, **kwargs)
        Response::Transcription.from_json(
          post_form_multipart(
            '/v1/audio/translations',
            file: form_file(file),
            model: model,
            **kwargs
          )
        )
      end
    end
  end
end
