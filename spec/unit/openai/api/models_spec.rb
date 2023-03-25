# frozen_string_literal: true

RSpec.describe OpenAI::API, '#models' do
  include_context 'an API Resource'

  let(:resource) { api.models }

  context 'when listing models' do
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
      models = resource.list

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

  context 'when retrieving a model' do
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
      model = resource.fetch('text-davinci-002')

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
end
