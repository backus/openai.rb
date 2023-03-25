# frozen_string_literal: true

class OpenAI
  class Chat
    include Anima.new(:messages, :settings, :api)

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
      response = api.chat_completions.create(
        **settings,
        messages: raw_messages
      )

      msg = response.choices.first.message

      add_message(msg.role, msg.content)
    end

    def last_message
      API::Response::ChatCompletion::Choice::Message.new(messages.last)
    end

    def to_log_format
      messages.map(&:to_log_format).join("\n\n")
    end

    private

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
        "#{role.upcase}: #{content}"
      end
    end
  end
end
