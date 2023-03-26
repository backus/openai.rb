# frozen_string_literal: true

RSpec.describe OpenAI::Chat do
  let(:messages) { [{ role: 'user', content: 'Hello' }] }
  let(:settings) { { model: 'gpt-3' } }
  let(:openai) { double('OpenAI') }

  describe 'initialization and adding messages' do
    it 'initializes with messages and adds user, system, and assistant messages' do
      chat = OpenAI::Chat.new(messages: messages, settings: settings, openai: openai)

      expect(chat.messages.count).to eq(1)
      expect(chat.messages.first.role).to eq('user')
      expect(chat.messages.first.content).to eq('Hello')

      chat = chat.add_user_message('How are you?')
      expect(chat.messages.count).to eq(2)
      expect(chat.messages.last.role).to eq('user')
      expect(chat.messages.last.content).to eq('How are you?')

      chat = chat.add_system_message('System message')
      expect(chat.messages.count).to eq(3)
      expect(chat.messages.last.role).to eq('system')
      expect(chat.messages.last.content).to eq('System message')

      chat = chat.add_assistant_message('I am fine, thank you.')
      expect(chat.messages.count).to eq(4)
      expect(chat.messages.last.role).to eq('assistant')
      expect(chat.messages.last.content).to eq('I am fine, thank you.')
    end
  end
end
