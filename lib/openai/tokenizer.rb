# frozen_string_literal: true

class OpenAI
  class Tokenizer
    include Equalizer.new

    UnknownModel = Class.new(StandardError)
    UnknownEncoding = Class.new(StandardError)

    def for_model(model)
      encoding = Tiktoken.encoding_for_model(model)
      raise UnknownModel, "Invalid model name or not recognized by Tiktoken: #{model.inspect}" if encoding.nil?

      Encoding.new(encoding.name)
    end

    def get(encoding_name)
      encoding = Tiktoken.get_encoding(encoding_name)
      if encoding.nil?
        raise UnknownEncoding,
              "Invalid encoding name or not recognized by Tiktoken: #{encoding_name.inspect}"
      end

      Encoding.new(encoding.name)
    end

    class Encoding
      include Concord.new(:name)

      def encode(text)
        encoder.encode(text)
      end
      alias tokenize encode

      def decode(tokens)
        encoder.decode(tokens)
      end

      def num_tokens(text)
        encode(text).size
      end

      private

      def encoder
        Tiktoken.get_encoding(name)
      end
    end
  end
end
