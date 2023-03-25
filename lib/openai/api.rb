# frozen_string_literal: true

class OpenAI
  class API
    include Concord.new(:client)

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

    def completions
      API::Completion.new(client)
    end

    def chat_completions
      API::ChatCompletion.new(client)
    end

    def embeddings
      API::Embedding.new(client)
    end

    def models
      API::Model.new(client)
    end

    def edits
      API::Edit.new(client)
    end

    def files
      API::File.new(client)
    end

    def fine_tunes
      API::FineTune.new(client)
    end

    def images
      API::Image.new(client)
    end

    def audio
      API::Audio.new(client)
    end

    def moderations
      API::Moderation.new(client)
    end
  end
end
