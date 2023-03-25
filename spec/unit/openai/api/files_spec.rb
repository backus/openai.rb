# frozen_string_literal: true

RSpec.describe OpenAI::API, '#files' do
  include_context 'an API Resource'

  let(:resource) { client.files }
  let(:sample_file) { OpenAISpec::SPEC_ROOT.join('data/sample.jsonl') }

  context 'when creating a file' do
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
      file = resource.create(
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

  context 'when listing a file' do
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
      files = resource.list

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

  context 'when deleting a file' do
    let(:response_body) do
      {
        "id": 'file-XjGxS3KTG0uNmNOK362iJua3',
        "object": 'file',
        "deleted": true
      }
    end

    it 'can delete a file' do
      file = resource.delete('file-XjGxS3KTG0uNmNOK362iJua3')

      expect(http)
        .to have_received(:delete)
        .with('https://api.openai.com/v1/files/file-XjGxS3KTG0uNmNOK362iJua3')

      expect(file.id).to eql('file-XjGxS3KTG0uNmNOK362iJua3')
      expect(file.object).to eql('file')
      expect(file.deleted?).to be_truthy
    end
  end

  context 'when fetching a file' do
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
      file = resource.fetch('file-XjGxS3KTG0uNmNOK362iJua3')

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

  context 'when fetching a file contents' do
    let(:response) do
      instance_double(
        HTTP::Response,
        status: HTTP::Response::Status.new(200),
        body: '(raw)'
      )
    end

    it 'can get a file contents' do
      response = resource.get_content('file-XjGxS3KTG0uNmNOK362iJua3')

      expect(http)
        .to have_received(:get)
        .with('https://api.openai.com/v1/files/file-XjGxS3KTG0uNmNOK362iJua3/content')

      expect(response).to eql('(raw)')
    end
  end
end
