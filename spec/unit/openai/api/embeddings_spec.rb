# frozen_string_literal: true

RSpec.describe OpenAI::API, '#embeddings' do
  include_context 'an API Resource'

  let(:resource) { api.embeddings }
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
    embedding = resource.create(model: 'text-embedding-ada-002', input: 'Hello, world!')

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
