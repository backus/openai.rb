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

  describe '#get_model' do
    let(:response_body) do
      {
        "id": 'text-davinci-002',
        "object": 'model',
        "owned_by": 'openai',
        "permission": %w[
          query
          completions
          models:read
          models:write
          engine:read
          engine:write
        ]
      }
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: JSON.dump(response_body)
      )
    end

    it 'can retrieve a model' do
      model = client.get_model('text-davinci-002')

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/models/text-davinci-002')

      expect(model.id).to eql('text-davinci-002')
      expect(model.object).to eql('model')
      expect(model.owned_by).to eql('openai')
      expect(model.permission).to eql(%w[
                                        query
                                        completions
                                        models:read
                                        models:write
                                        engine:read
                                        engine:write
                                      ])
    end
  end

  describe '#create_edit' do
    let(:response_body) do
      {
        "object": 'edit',
        "created": 1_589_478_378,
        "choices": [
          {
            "text": 'What day of the week is it?',
            "index": 0
          }
        ],
        "usage": {
          "prompt_tokens": 25,
          "completion_tokens": 32,
          "total_tokens": 57
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

    it 'can create an edit' do
      edit = client.create_edit(model: 'text-davinci-002',
                                instruction: 'Change "world" to "solar system" in the following text: "Hello, world!"')

      expect(http)
        .to have_received(:post)
        .with('https://api.openai.com/v1/edits', hash_including(:json))

      expect(edit.object).to eql('edit')
      expect(edit.choices.first.text).to eql('What day of the week is it?')
      expect(edit.choices.first.index).to eql(0)
      expect(edit.usage.prompt_tokens).to eql(25)
      expect(edit.usage.completion_tokens).to eql(32)
      expect(edit.usage.total_tokens).to eql(57)
    end
  end

  describe '#create_image_generation' do
    let(:response_body) do
      {
        created: Time.now.to_i,
        data: [
          { url: 'https://example.com/image1.png' },
          { url: 'https://example.com/image2.png' }
        ]
      }
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: JSON.dump(response_body)
      )
    end

    it 'can create an image generation' do
      image_generation = client.create_image_generation(prompt: 'a bird in the forest', size: 512)

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/images/generations',
          hash_including(
            json: hash_including(prompt: 'a bird in the forest', size: 512)
          )
        )

      expect(image_generation.created).to be_within(1).of(Time.now.to_i)
      expect(image_generation.data.map(&:url)).to contain_exactly('https://example.com/image1.png', 'https://example.com/image2.png')
    end
  end

  describe '#create_file' do
    let(:sample_file) { OpenAISpec::SPEC_ROOT.join('data/sample.jsonl') }

    let(:response_body) do
      {
        "id": 'file-XjGxS3KTG0uNmNOK362iJua3',
        "object": 'file',
        "bytes": 140,
        "created_at": 1_613_779_121,
        "filename": 'sample.jsonl',
        "purpose": 'fine-tune'
      }
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: JSON.dump(response_body)
      )
    end

    it 'can create a file' do
      file = client.create_file(
        file: sample_file,
        purpose: 'fine-tune'
      )

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/files',
          hash_including(
            form: hash_including(
              {
                file: instance_of(HTTP::FormData::File),
                purpose: 'fine-tune'
              }
            )
          )
        )

      expect(file.id).to eql('file-XjGxS3KTG0uNmNOK362iJua3')
      expect(file.object).to eql('file')
      expect(file.bytes).to eql(140)
      expect(file.created_at).to eql(1_613_779_121)
      expect(file.filename).to eql('sample.jsonl')
      expect(file.purpose).to eql('fine-tune')
    end
  end
end
