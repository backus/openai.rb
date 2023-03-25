# frozen_string_literal: true

RSpec.describe OpenAI, '#chat_completions' do
  include_context 'an API Resource'

  let(:resource) { client.chat_completions }
  let(:response_body) do
    {
      "id": 'chatcmpl-123',
      "object": 'chat.completion',
      "created": 1_677_652_288,
      "choices": [
        {
          "index": 0,
          "message": {
            "role": 'assistant',
            "content": "\n\nHello there, how may I assist you today?"
          },
          "finish_reason": 'stop'
        }
      ],
      "usage": {
        "prompt_tokens": 9,
        "completion_tokens": 12,
        "total_tokens": 21
      }
    }
  end

  it 'can create a chat completion' do
    messages = [
      { "text": 'Hello there!', "user": 'customer' },
      { "text": 'Can you help me with my order?', "user": 'customer' },
      { "text": 'Sure, what would you like to do?', "user": 'assistant' }
    ]
    completion = resource.create(model: 'text-davinci-002', messages: messages)

    expect(completion.id).to eql('chatcmpl-123')
    expect(completion.choices.first.index).to eql(0)
    expect(completion.choices.first.message.role).to eql('assistant')
    expect(completion.choices.first.message.content).to eql("\n\nHello there, how may I assist you today?")
    expect(completion.choices.first.finish_reason).to eql('stop')
    expect(completion.usage.prompt_tokens).to eql(9)
    expect(completion.usage.completion_tokens).to eql(12)
    expect(completion.usage.total_tokens).to eql(21)
  end
end
