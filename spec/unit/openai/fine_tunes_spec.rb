# frozen_string_literal: true

RSpec.describe OpenAI, '#fine_tunes' do
  include_context 'an API Resource'

  let(:resource) { client.fine_tunes }
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

  context 'when listing fine-tunes' do
    it 'can get a list of fine-tunes' do
      fine_tunes = resource.list

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

  context 'when creating a fine-tune' do
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
      fine_tune = resource.create(training_file: 'my-data-train.jsonl', model: 'curie')

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

  context 'when fetching a fine tune' do
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
      fine_tune = resource.fetch('ft-AF1WoRqd3aJAHsqc9NY7iL8F')

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

  context 'when canceling a fine-tune' do
    let(:response_body) do
      {
        "id": 'ft-xhrpBbvVUzYGo8oUO1FY4nI7',
        "status": 'cancelled'
      }
    end

    it 'can cancel a fine-tune' do
      fine_tune = resource.cancel('ft-xhrpBbvVUzYGo8oUO1FY4nI7')

      expect(http)
        .to have_received(:post)
        .with('https://api.openai.com/v1/fine-tunes/ft-xhrpBbvVUzYGo8oUO1FY4nI7/cancel', json: {})

      expect(fine_tune.id).to eql('ft-xhrpBbvVUzYGo8oUO1FY4nI7')
      expect(fine_tune.status).to eql('cancelled')
    end
  end
end
