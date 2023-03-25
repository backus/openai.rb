# frozen_string_literal: true

RSpec.describe OpenAI do
  let(:client) { described_class.new('sk-123', http: http) }
  let(:http)   { class_spy(HTTP)                     }

  before do
    allow(http).to receive(:post).and_return(response)
    allow(http).to receive(:get).and_return(response)
    allow(http).to receive(:delete).and_return(response)
  end

  let(:response) do
    instance_double(
      HTTP::Response,
      status: HTTP::Response::Status.new(200),
      body: JSON.dump(response_body)
    )
  end

  describe '#completions.create' do
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

    it 'authenticates requests' do
      client.completions.create(model: 'text-davinci-002', prompt: 'Hello, world!')

      expect(http).to have_received(:headers).with(
        hash_including(
          'Authorization' => 'Bearer sk-123'
        )
      )
    end

    it 'can create a completion' do
      completion = client.completions.create(model: 'text-davinci-002', prompt: 'Hello, world!')

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

  describe '#chat_completions.create' do
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
      completion = client.chat_completions.create(model: 'text-davinci-002', messages: messages)

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

  describe '#embeddings.create' do
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

    it 'can create an embedding' do
      embedding = client.embeddings.create(model: 'text-embedding-ada-002', input: 'Hello, world!')

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

  describe '#models.list' do
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

    it 'can list all models' do
      models = client.models.list

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

  describe '#models.get' do
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

    it 'can retrieve a model' do
      model = client.models.get('text-davinci-002')

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

  describe '#edits.create' do
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

    it 'can create an edit' do
      edit = client.edits.create(model: 'text-davinci-002',
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

  describe '#images.create' do
    let(:response_body) do
      {
        created: Time.now.to_i,
        data: [
          { url: 'https://example.com/image1.png' },
          { url: 'https://example.com/image2.png' }
        ]
      }
    end

    it 'can create an image generation' do
      image_generation = client.images.create(prompt: 'a bird in the forest', size: 512)

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

  describe '#files.create' do
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

    it 'can create a file' do
      file = client.files.create(
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
      expect(file.deleted?).to be(nil)
    end
  end

  describe '#files.list' do
    let(:response_body) do
      {
        "data": [
          {
            "id": 'file-ccdDZrC3iZVNiQVeEA6Z66wf',
            "object": 'file',
            "bytes": 175,
            "created_at": 1_613_677_385,
            "filename": 'train.jsonl',
            "purpose": 'search'
          },
          {
            "id": 'file-XjGxS3KTG0uNmNOK362iJua3',
            "object": 'file',
            "bytes": 140,
            "created_at": 1_613_779_121,
            "filename": 'puppy.jsonl',
            "purpose": 'search'
          }
        ],
        "object": 'list'
      }
    end

    it 'can get a list of files' do
      files = client.files.list

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/files')

      expect(files.data.size).to eql(2)
      expect(files.data.first.id).to eql('file-ccdDZrC3iZVNiQVeEA6Z66wf')
      expect(files.data.first.object).to eql('file')
      expect(files.data.first.bytes).to eql(175)
      expect(files.data.first.created_at).to eql(1_613_677_385)
      expect(files.data.first.filename).to eql('train.jsonl')
      expect(files.data.first.purpose).to eql('search')
      expect(files.object).to eql('list')
    end
  end

  describe '#files.delete' do
    let(:response_body) do
      {
        "id": 'file-XjGxS3KTG0uNmNOK362iJua3',
        "object": 'file',
        "deleted": true
      }
    end

    it 'can delete a file' do
      file = client.files.delete('file-XjGxS3KTG0uNmNOK362iJua3')

      expect(http)
        .to have_received(:delete)
        .with('https://api.openai.com/v1/files/file-XjGxS3KTG0uNmNOK362iJua3')

      expect(file.id).to eql('file-XjGxS3KTG0uNmNOK362iJua3')
      expect(file.object).to eql('file')
      expect(file.deleted?).to be_truthy
    end
  end

  describe '#files.get' do
    let(:response_body) do
      {
        "id": 'file-XjGxS3KTG0uNmNOK362iJua3',
        "object": 'file',
        "bytes": 140,
        "created_at": 1_613_779_657,
        "filename": 'mydata.jsonl',
        "purpose": 'fine-tune'
      }
    end

    it 'can get a file' do
      file = client.files.get('file-XjGxS3KTG0uNmNOK362iJua3')

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/files/file-XjGxS3KTG0uNmNOK362iJua3')

      expect(file.id).to eql('file-XjGxS3KTG0uNmNOK362iJua3')
      expect(file.object).to eql('file')
      expect(file.bytes).to eql(140)
      expect(file.created_at).to eql(1_613_779_657)
      expect(file.filename).to eql('mydata.jsonl')
      expect(file.purpose).to eql('fine-tune')
    end
  end

  describe '#files.get_content' do
    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: '(raw)'
      )
    end

    it 'can get a file contents' do
      response = client.files.get_content('file-XjGxS3KTG0uNmNOK362iJua3')

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/files/file-XjGxS3KTG0uNmNOK362iJua3/content')

      expect(response).to eql('(raw)')
    end
  end

  describe '#fine_tunes.list' do
    let(:response_body) do
      {
        "object": 'list',
        "data": [
          {
            "id": 'ft-AF1WoRqd3aJAHsqc9NY7iL8F',
            "object": 'fine-tune',
            "model": 'curie',
            "created_at": 1_614_807_352,
            "fine_tuned_model": nil,
            "hyperparams": {},
            "organization_id": 'org-...',
            "result_files": [],
            "status": 'pending',
            "validation_files": [],
            "training_files": [{}],
            "updated_at": 1_614_807_352
          },
          {},
          {}
        ]
      }
    end

    it 'can get a list of fine-tunes' do
      fine_tunes = client.fine_tunes.list

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/fine-tunes')

      expect(fine_tunes.object).to eql('list')
      expect(fine_tunes.data.size).to eql(3)
      expect(fine_tunes.data.first.id).to eql('ft-AF1WoRqd3aJAHsqc9NY7iL8F')
      expect(fine_tunes.data.first.object).to eql('fine-tune')
      expect(fine_tunes.data.first.model).to eql('curie')
      expect(fine_tunes.data.first.created_at).to eql(1_614_807_352)
      expect(fine_tunes.data.first.fine_tuned_model).to be_nil
      expect(fine_tunes.data.first.hyperparams).to eql(
        OpenAI::Response::FineTune::Hyperparams.new({})
      )
      expect(fine_tunes.data.first.organization_id).to eql('org-...')
      expect(fine_tunes.data.first.result_files).to eql([])
      expect(fine_tunes.data.first.status).to eql('pending')
      expect(fine_tunes.data.first.validation_files).to eql([])
      expect(fine_tunes.data.first.training_files).to eql(
        [
          OpenAI::Response::FineTune::File.new({})
        ]
      )
      expect(fine_tunes.data.first.updated_at).to eql(1_614_807_352)
    end
  end

  describe '#fine_tunes.create' do
    let(:response_body) do
      {
        "id": 'ft-AF1WoRqd3aJAHsqc9NY7iL8F',
        "object": 'fine-tune',
        "model": 'curie',
        "created_at": 1_614_807_352,
        "events": [
          {
            "object": 'fine-tune-event',
            "created_at": 1_614_807_352,
            "level": 'info',
            "message": 'Job enqueued. Waiting for jobs ahead to complete. Queue number: 0.'
          }
        ],
        "fine_tuned_model": nil,
        "hyperparams": {
          "batch_size": 4,
          "learning_rate_multiplier": 0.1,
          "n_epochs": 4,
          "prompt_loss_weight": 0.1
        },
        "organization_id": 'org-...',
        "result_files": [],
        "status": 'pending',
        "validation_files": [],
        "training_files": [
          {
            "id": 'file-XGinujblHPwGLSztz8cPS8XY',
            "object": 'file',
            "bytes": 1_547_276,
            "created_at": 1_610_062_281,
            "filename": 'my-data-train.jsonl',
            "purpose": 'fine-tune-train'
          }
        ],
        "updated_at": 1_614_807_352
      }
    end

    it 'can create a fine-tune' do
      fine_tune = client.fine_tunes.create(training_file: 'my-data-train.jsonl', model: 'curie')

      expect(http)
        .to have_received(:post)
        .with('https://api.openai.com/v1/fine-tunes', hash_including(:json))

      expect(fine_tune.id).to eql('ft-AF1WoRqd3aJAHsqc9NY7iL8F')
      expect(fine_tune.model).to eql('curie')
      expect(fine_tune.created_at).to eql(1_614_807_352)
      expect(fine_tune.events.first.object).to eql('fine-tune-event')
      expect(fine_tune.events.first.created_at).to eql(1_614_807_352)
      expect(fine_tune.events.first.level).to eql('info')
      expect(fine_tune.events.first.message).to eql('Job enqueued. Waiting for jobs ahead to complete. Queue number: 0.')
      expect(fine_tune.fine_tuned_model).to be_nil
      expect(fine_tune.hyperparams.batch_size).to eql(4)
      expect(fine_tune.hyperparams.learning_rate_multiplier).to eql(0.1)
      expect(fine_tune.hyperparams.n_epochs).to eql(4)
      expect(fine_tune.hyperparams.prompt_loss_weight).to eql(0.1)
      expect(fine_tune.organization_id).to eql('org-...')
      expect(fine_tune.result_files).to be_empty
      expect(fine_tune.status).to eql('pending')
      expect(fine_tune.validation_files).to be_empty
      expect(fine_tune.training_files.first.id).to eql('file-XGinujblHPwGLSztz8cPS8XY')
      expect(fine_tune.training_files.first.object).to eql('file')
      expect(fine_tune.training_files.first.bytes).to eql(1_547_276)
      expect(fine_tune.training_files.first.created_at).to eql(1_610_062_281)
      expect(fine_tune.training_files.first.filename).to eql('my-data-train.jsonl')
      expect(fine_tune.training_files.first.purpose).to eql('fine-tune-train')
      expect(fine_tune.updated_at).to eql(1_614_807_352)
    end
  end

  describe '#fine_tunes.get' do
    let(:response_body) do
      {
        "id": 'ft-AF1WoRqd3aJAHsqc9NY7iL8F',
        "object": 'fine-tune',
        "model": 'curie',
        "created_at": 1_614_807_352,
        "events": [
          {
            "object": 'fine-tune-event',
            "created_at": 1_614_807_352,
            "level": 'info',
            "message": 'Job enqueued. Waiting for jobs ahead to complete. Queue number: 0.'
          },
          {
            "object": 'fine-tune-event',
            "created_at": 1_614_807_356,
            "level": 'info',
            "message": 'Job started.'
          },
          {
            "object": 'fine-tune-event',
            "created_at": 1_614_807_861,
            "level": 'info',
            "message": 'Uploaded snapshot: curie:ft-acmeco-2021-03-03-21-44-20.'
          },
          {
            "object": 'fine-tune-event',
            "created_at": 1_614_807_864,
            "level": 'info',
            "message": 'Uploaded result files: file-QQm6ZpqdNwAaVC3aSz5sWwLT.'
          },
          {
            "object": 'fine-tune-event',
            "created_at": 1_614_807_864,
            "level": 'info',
            "message": 'Job succeeded.'
          }
        ],
        "fine_tuned_model": 'curie:ft-acmeco-2021-03-03-21-44-20',
        "hyperparams": {
          "batch_size": 4,
          "learning_rate_multiplier": 0.1,
          "n_epochs": 4,
          "prompt_loss_weight": 0.1
        },
        "organization_id": 'org-...',
        "result_files": [
          {
            "id": 'file-QQm6ZpqdNwAaVC3aSz5sWwLT',
            "object": 'file',
            "bytes": 81_509,
            "created_at": 1_614_807_863,
            "filename": 'compiled_results.csv',
            "purpose": 'fine-tune-results'
          }
        ],
        "status": 'succeeded',
        "validation_files": [],
        "training_files": [
          {
            "id": 'file-XGinujblHPwGLSztz8cPS8XY',
            "object": 'file',
            "bytes": 1_547_276,
            "created_at": 1_610_062_281,
            "filename": 'my-data-train.jsonl',
            "purpose": 'fine-tune-train'
          }
        ],
        "updated_at": 1_614_807_865
      }
    end

    it 'can get a fine-tune' do
      fine_tune = client.fine_tunes.get('ft-AF1WoRqd3aJAHsqc9NY7iL8F')

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/fine-tunes/ft-AF1WoRqd3aJAHsqc9NY7iL8F')

      expect(fine_tune.id).to eql('ft-AF1WoRqd3aJAHsqc9NY7iL8F')
      expect(fine_tune.model).to eql('curie')
      expect(fine_tune.created_at).to eql(1_614_807_352)
      expect(fine_tune.events.first.object).to eql('fine-tune-event')
      expect(fine_tune.events.first.created_at).to eql(1_614_807_352)
      expect(fine_tune.events.first.level).to eql('info')
      expect(fine_tune.events.first.message).to eql('Job enqueued. Waiting for jobs ahead to complete. Queue number: 0.')
      expect(fine_tune.fine_tuned_model).to eql('curie:ft-acmeco-2021-03-03-21-44-20')
      expect(fine_tune.hyperparams.batch_size).to eql(4)
      expect(fine_tune.hyperparams.learning_rate_multiplier).to eql(0.1)
      expect(fine_tune.hyperparams.n_epochs).to eql(4)
      expect(fine_tune.hyperparams.prompt_loss_weight).to eql(0.1)
      expect(fine_tune.organization_id).to eql('org-...')
      expect(fine_tune.result_files.first.id).to eql('file-QQm6ZpqdNwAaVC3aSz5sWwLT')
      expect(fine_tune.result_files.first.object).to eql('file')
      expect(fine_tune.result_files.first.bytes).to eql(81_509)
      expect(fine_tune.result_files.first.created_at).to eql(1_614_807_863)
      expect(fine_tune.result_files.first.filename).to eql('compiled_results.csv')
      expect(fine_tune.result_files.first.purpose).to eql('fine-tune-results')
      expect(fine_tune.status).to eql('succeeded')
      expect(fine_tune.validation_files).to be_empty
      expect(fine_tune.training_files.first.id).to eql('file-XGinujblHPwGLSztz8cPS8XY')
      expect(fine_tune.training_files.first.object).to eql('file')
      expect(fine_tune.training_files.first.bytes).to eql(1_547_276)
      expect(fine_tune.training_files.first.created_at).to eql(1_610_062_281)
      expect(fine_tune.training_files.first.filename).to eql('my-data-train.jsonl')
      expect(fine_tune.training_files.first.purpose).to eql('fine-tune-train')
      expect(fine_tune.updated_at).to eql(1_614_807_865)
    end
  end

  describe '#fine_tunes.cancel' do
    let(:response_body) do
      {
        "id": 'ft-xhrpBbvVUzYGo8oUO1FY4nI7',
        "status": 'cancelled'
      }
    end

    it 'can cancel a fine-tune' do
      fine_tune = client.fine_tunes.cancel('ft-xhrpBbvVUzYGo8oUO1FY4nI7')

      expect(http)
        .to have_received(:post)
        .with('https://api.openai.com/v1/fine-tunes/ft-xhrpBbvVUzYGo8oUO1FY4nI7/cancel', json: {})

      expect(fine_tune.id).to eql('ft-xhrpBbvVUzYGo8oUO1FY4nI7')
      expect(fine_tune.status).to eql('cancelled')
    end
  end

  describe '#transcribe_audio' do
    let(:sample_audio) { OpenAISpec::SPEC_ROOT.join('data/sample.mp3') }

    let(:response_body) do
      {
        "text": "Imagine the wildest idea that you've ever had, and you're curious about how it might scale to something that's a 100, a 1,000 times bigger. This is a place where you can get to do that."
      }
    end

    it 'can transcribe audio' do
      transcription = client.transcribe_audio(
        file: sample_audio,
        model: 'model-1234'
      )

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/audio/transcriptions',
          hash_including(
            form: hash_including(
              {
                file: instance_of(HTTP::FormData::File),
                model: 'model-1234'
              }
            )
          )
        )

      expect(transcription.text).to eql("Imagine the wildest idea that you've ever had, and you're curious about how it might scale to something that's a 100, a 1,000 times bigger. This is a place where you can get to do that.")
    end
  end

  describe '#translate_audio' do
    let(:sample_audio) { OpenAISpec::SPEC_ROOT.join('data/sample_french.mp3') }

    let(:response_body) do
      {
        "text": 'Hello, my name is Wolfgang and I come from Germany. Where are you heading today?'
      }
    end

    it 'can translate audio' do
      translation = client.translate_audio(
        file: sample_audio,
        model: 'model-id',
        prompt: 'Hello, my name is Wolfgang and I come from Germany. Where are you heading today?',
        response_format: 'text',
        temperature: 0.5
      )

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/audio/translations',
          hash_including(
            form: hash_including(
              {
                file: instance_of(HTTP::FormData::File),
                model: 'model-id',
                prompt: 'Hello, my name is Wolfgang and I come from Germany. Where are you heading today?',
                response_format: 'text',
                temperature: 0.5
              }
            )
          )
        )

      expect(translation.text).to eql('Hello, my name is Wolfgang and I come from Germany. Where are you heading today?')
    end
  end
end
