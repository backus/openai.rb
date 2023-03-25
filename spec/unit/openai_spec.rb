# frozen_string_literal: true

RSpec.describe OpenAI do
  let(:client) { described_class.new('sk-123', http: http) }
  let(:http)   { class_spy(HTTP)                     }

  before do
    allow(http).to receive(:post).and_return(response)
  end

  describe '#create_completion' do
    let(:response_body) do
      {
        "id": 'cmpl-uqkvlQyYK7bGYrRHQ0eXlWi7',
        "object": 'text_completion',
        "created": 1_589_478_378,
        "model": 'text-davinci-003',
        "choices": [
          {
            "text": "\n\nThis is indeed a test",
            "index": 0,
            "logprobs": nil,
            "finish_reason": 'length'
          }
        ],
        "usage": {
          "prompt_tokens": 5,
          "completion_tokens": 7,
          "total_tokens": 12
        }
      }
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: JSON.dump(response_body)
      )
    end

    it 'authenticates requests' do
      client.create_completion(model: 'text-davinci-002', prompt: 'Hello, world!')

      expect(http).to have_received(:headers).with(
        hash_including(
          'Authorization' => 'Bearer sk-123'
        )
      )
    end

    it 'can create a completion' do
      completion = client.create_completion(model: 'text-davinci-002', prompt: 'Hello, world!')

      expect(completion.id).to eql('cmpl-uqkvlQyYK7bGYrRHQ0eXlWi7')
      expect(completion.model).to eql('text-davinci-003')
      expect(completion.choices.first.text).to eql("\n\nThis is indeed a test")
      expect(completion.choices.first.index).to eql(0)
      expect(completion.choices.first.logprobs).to be_nil
      expect(completion.choices.first.finish_reason).to eql('length')
      expect(completion.usage.prompt_tokens).to eql(5)
      expect(completion.usage.completion_tokens).to eql(7)
      expect(completion.usage.total_tokens).to eql(12)
    end
  end

  describe '#create_chat_completion' do
    let(:response_body) do
      {
        "id": 'chatcmpl-123',
        "object": 'chat.completion',
        "created": 1_677_652_288,
        "choices": [{
          "index": 0,
          "message": {
            "role": 'assistant',
            "content": "\n\nHello there, how may I assist you today?"
          },
          "finish_reason": 'stop'
        }],
        "usage": {
          "prompt_tokens": 9,
          "completion_tokens": 12,
          "total_tokens": 21
        }
      }
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: JSON.dump(response_body)
      )
    end

    it 'can create a chat completion' do
      completion = client.create_chat_completion(
        model: 'gpt-3.5-turbo',
        messages: [
          {
            text: 'Hi there!',
            speaker: 'user'
          },
          {
            text: 'Hello there, how may I assist you today?',
            speaker: 'assistant'
          }
        ],
        temperature: 1,
        top_p: 1,
        n: 1,
        stream: false,
        stop: nil,
        max_tokens: Float::INFINITY,
        presence_penalty: 0,
        frequency_penalty: 0,
        logit_bias: nil,
        user: nil
      )

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
end
