# frozen_string_literal: true

class OpenAI
  class Chat
    include Anima.new(:messages, :settings, :openai)
    using Util::Colorize

    def initialize(messages:, **kwargs)
      messages = messages.map do |msg|
        if msg.is_a?(Hash)
          Message.new(msg)
        else
          msg
        end
      end

      super(messages: messages, **kwargs)
    end

    def add_user_message(message)
      add_message('user', message)
    end
    alias user add_user_message

    def add_system_message(message)
      add_message('system', message)
    end
    alias system add_system_message

    def add_assistant_message(message)
      add_message('assistant', message)
    end
    alias assistant add_assistant_message

    def submit
      openai.logger.info("[Chat] [tokens=#{total_tokens}] Submitting messages:\n\n#{to_log_format}")

      response = openai.api.chat_completions.create(
        **settings,
        messages: raw_messages
      )

      msg = response.choices.first.message

      add_message(msg.role, msg.content).tap do |new_chat|
        openai.logger.info("[Chat] Response:\n\n#{new_chat.last_message.to_log_format}")
      end
    end

    def last_message
      messages.last
    end

    def to_log_format
      messages.map(&:to_log_format).join("\n\n")
    end

    private

    def total_tokens
      openai.tokens.for_model(settings.fetch(:model)).num_tokens(messages.map(&:content).join(' '))
    end

    def raw_messages
      messages.map(&:to_h)
    end

    def add_message(role, content)
      with_message(role: role, content: content)
    end

    def with_message(message)
      with(messages: messages + [message])
    end

    class Message
      include Anima.new(:role, :content)

      def to_log_format
        prefix =
          case role
          when 'user' then "#{role}:".upcase.green
          when 'system' then "#{role}:".upcase.yellow
          when 'assistant' then "#{role}:".upcase.red
          else
            raise "Unknown role: #{role}"
          end

        "#{prefix} #{content}"
      end
    end
  end
end
