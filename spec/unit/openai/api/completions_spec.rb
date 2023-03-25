# frozen_string_literal: true

RSpec.describe OpenAI::API, '#completions' do
  include_context 'an API Resource'

  let(:resource) { api.completions }

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

  it 'can create a completion' do
    completion = resource.create(model: 'text-davinci-002', prompt: 'Hello, world!')

    expect(http)
      .to have_received(:post)
      .with('https://api.openai.com/v1/completions', hash_including(:json))

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

  it 'raises when a block is given for a non-streaming request' do
    expect { resource.create(model: 'text-davinci-002', prompt: 'Hello, world!') { print 'noop' } }
      .to raise_error('Non-streaming responses do not support blocks')
  end

  context 'when streaming is enabled' do
    let(:response_chunks) do
      [
        chunk('He'),
        chunk('llo,'),
        chunk(' world'),
        chunk('!', finish_reason: 'stop')
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
          .and_yield('data: [DONE]')
      end
    end

    before do
      allow(http).to receive(:persistent).and_yield(http)
    end

    def chunk(text, finish_reason: nil)
      data = {
        "id": 'cmpl-6y5B6Ak8wBk2nKsqVtSlFeJAG1dUM',
        "object": 'text_completion',
        "created": 1_679_777_604,
        "choices": [{
          "text": text,
          "index": 0,
          "logprobs": nil,
          "finish_reason": finish_reason
        }],
        "model": 'text-davinci-002'
      }

      "data: #{JSON.dump(data)}"
    end

    it 'yields chunks as they are served' do
      chunks = []
      resource.create(model: 'text-davinci-002', prompt: 'Hello, world!', stream: true) do |chunk|
        chunks << chunk
      end

      expect(chunks).to all(be_an_instance_of(OpenAI::API::Response::Completion))
      texts = chunks.map { |chunk| chunk.choices.first.text }
      expect(texts.join('')).to eql('Hello, world!')
    end

    it 'raises when a block is not given' do
      expect { resource.create(model: 'text-davinci-002', prompt: 'Hello, world!', stream: true) }
        .to raise_error('Streaming responses require a block')
    end
  end
end
