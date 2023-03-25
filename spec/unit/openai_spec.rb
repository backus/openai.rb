# frozen_string_literal: true

RSpec.describe OpenAI do
  let(:client) { described_class.new('sk-123', http: http) }
  let(:http)   { class_spy(HTTP)                     }

  before do
    allow(http).to receive(:post).and_return(response)
    allow(http).to receive(:get).and_return(response)
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
  end

  describe '#create_chat_completion' do
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

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: JSON.dump(response_body)
      )
    end

    it 'can create a chat completion' do
      messages = [
        { "text": 'Hello there!', "user": 'customer' },
        { "text": 'Can you help me with my order?', "user": 'customer' },
        { "text": 'Sure, what would you like to do?', "user": 'assistant' }
      ]
      completion = client.create_chat_completion(model: 'text-davinci-002', messages: messages)

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

  describe '#create_embedding' do
    let(:response_body) do
      {
        "object": 'list',
        "data": [
          {
            "object": 'embedding',
            "embedding": [
              0.0023064255,
              -0.009327292,
              -0.0028842222
            ],
            "index": 0
          }
        ],
        "model": 'text-embedding-ada-002',
        "usage": {
          "prompt_tokens": 8,
          "total_tokens": 8
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

    it 'can create an embedding' do
      embedding = client.create_embedding(model: 'text-embedding-ada-002', input: 'Hello, world!')

      expect(http)
        .to have_received(:post)
        .with('https://api.openai.com/v1/embeddings', hash_including(:json))

      expect(embedding.object).to eql('list')
      expect(embedding.data.first.object).to eql('embedding')
      expect(embedding.data.first.embedding.length).to eql(3)
      expect(embedding.data.first.embedding.first).to eql(0.0023064255)
      expect(embedding.data.first.index).to eql(0)
      expect(embedding.model).to eql('text-embedding-ada-002')
      expect(embedding.usage.prompt_tokens).to eql(8)
      expect(embedding.usage.total_tokens).to eql(8)
    end
  end

  describe '#list_models' do
    let(:response_body) do
      {
        data: [
          {
            id: 'model-id-0',
            object: 'model',
            owned_by: 'organization-owner',
            permission: [1, 2, 3]
          },
          {
            id: 'model-id-1',
            object: 'model',
            owned_by: 'organization-owner',
            permission: [4, 5, 6]
          },
          {
            id: 'model-id-2',
            object: 'model',
            owned_by: 'openai',
            permission: [7, 8, 9]
          }
        ],
        object: 'list'
      }
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: JSON.dump(response_body)
      )
    end

    it 'can list all models' do
      models = client.list_models

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/models')

      expect(models.data.length).to eql(3)

      expect(models.data[0].id).to eql('model-id-0')
      expect(models.data[0].object).to eql('model')
      expect(models.data[0].owned_by).to eql('organization-owner')
      expect(models.data[0].permission).to eql([1, 2, 3])

      expect(models.data[1].id).to eql('model-id-1')
      expect(models.data[1].object).to eql('model')
      expect(models.data[1].owned_by).to eql('organization-owner')
      expect(models.data[1].permission).to eql([4, 5, 6])

      expect(models.data[2].id).to eql('model-id-2')
      expect(models.data[2].object).to eql('model')
      expect(models.data[2].owned_by).to eql('openai')
      expect(models.data[2].permission).to eql([7, 8, 9])
    end
  end
end
