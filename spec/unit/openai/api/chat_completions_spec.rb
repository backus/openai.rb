# frozen_string_literal: true

RSpec.describe OpenAI::API, '#chat_completions' do
  include_context 'an API Resource'

  let(:resource) { api.chat_completions }
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

  let(:completion) do
    messages = [
      { "text": 'Hello there!', "user": 'customer' },
      { "text": 'Can you help me with my order?', "user": 'customer' },
      { "text": 'Sure, what would you like to do?', "user": 'assistant' }
    ]
    resource.create(model: 'text-davinci-002', messages: messages)
  end

  it 'can create a chat completion' do
    expect(completion.id).to eql('chatcmpl-123')
    expect(completion.choices.first.index).to eql(0)
    expect(completion.choices.first.message.role).to eql('assistant')
    expect(completion.choices.first.message.content).to eql("\n\nHello there, how may I assist you today?")
    expect(completion.choices.first.finish_reason).to eql('stop')
    expect(completion.usage.prompt_tokens).to eql(9)
    expect(completion.usage.completion_tokens).to eql(12)
    expect(completion.usage.total_tokens).to eql(21)
  end

  it 'exposes a #response_text helper method' do
    expect(completion.response_text).to eql("\n\nHello there, how may I assist you today?")
  end

  it 'exposes a #response helper method' do
    expect(completion.response.content).to eql("\n\nHello there, how may I assist you today?")
    expect(completion.response.role).to eql('assistant')
  end

  it 'raises when a block is given for a non-streaming request' do
    expect { resource.create(model: 'text-davinci-002', messages: []) { print 'noop' } }
      .to raise_error('Non-streaming responses do not support blocks')
  end

  context 'when streaming is enabled' do
    let(:response_chunks) do
      [
        chunk(role: 'assistant'),
        chunk(content: 'He'),
        chunk(content: 'llo,'),
        chunk(content: ' world'),
        chunk({ content: '!' }, finish_reason: 'stop')
      ]
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(response_status_code),
        body: response_body
      )
    end

    let(:response_body) do
      instance_double(HTTP::Response::Body).tap do |double|
        allow(double).to receive(:each)
          .and_yield(response_chunks.first)
          .and_yield(response_chunks[1])
          .and_yield(response_chunks[2])
          .and_yield(response_chunks[3])
          .and_yield(response_chunks[4])
          .and_yield('data: [DONE]')
      end
    end

    before do
      allow(http).to receive(:persistent).and_yield(http)
    end

    def chunk(delta, finish_reason: nil)
      data = {
        id: 'chatcmpl-6y5rBH2fvMeGqAAH81Wkp8QdqESEx',
        object: 'chat.completion.chunk',
        created: 1_679_780_213,
        model: 'gpt-3.5-turbo-0301',
        choices: [delta: delta, index: 0, finish_reason: finish_reason]
      }

      "data: #{JSON.dump(data)}"
    end

    it 'yields chunks as they are served' do
      chunks = []
      resource.create(model: 'text-davinci-002', messages: [], stream: true) do |chunk|
        chunks << chunk
      end

      expect(chunks).to all(be_an_instance_of(OpenAI::API::Response::ChatCompletionChunk))
      texts = chunks.map { |chunk| chunk.choices.first.delta.content }
      expect(texts.join('')).to eql('Hello, world!')

      expect(chunks[0].response.role).to eql('assistant')
      expect(chunks[1].response_text).to eql('He')
    end

    it 'raises when a block is not given' do
      expect { resource.create(model: 'text-davinci-002', messages: [], stream: true) }
        .to raise_error('Streaming responses require a block')
    end
  end
end
