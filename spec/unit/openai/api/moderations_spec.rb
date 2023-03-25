RSpec.describe OpenAI::API, '#moderations' do
  include_context 'an API Resource'

  let(:resource) { client.moderations }

  let(:response_body) do
    {
      "id": 'modr-5MWoLO',
      "model": 'text-moderation-001',
      "results": [
        {
          "categories": {
            "hate": false,
            "hate/threatening": true,
            "self-harm": false,
            "sexual": false,
            "sexual/minors": false,
            "violence": true,
            "violence/graphic": false
          },
          "category_scores": {
            "hate": 0.22714105248451233,
            "hate/threatening": 0.4132447838783264,
            "self-harm": 0.005232391878962517,
            "sexual": 0.01407341007143259,
            "sexual/minors": 0.0038522258400917053,
            "violence": 0.9223177433013916,
            "violence/graphic": 0.036865197122097015
          },
          "flagged": true
        }
      ]
    }
  end

  it 'can create a moderation' do
    moderation = resource.create(input: 'This is a test', model: 'text-moderation-001')

    expect(http)
      .to have_received(:post)
      .with('https://api.openai.com/v1/moderations', hash_including(:json))

    expect(moderation.id).to eql('modr-5MWoLO')
    expect(moderation.model).to eql('text-moderation-001')
    expect(moderation.results.first.categories.hate).to be_falsey
    expect(moderation.results.first.categories.hate_threatening).to be_truthy
    expect(moderation.results.first.categories.self_harm).to be_falsey
    expect(moderation.results.first.categories.sexual).to be_falsey
    expect(moderation.results.first.categories.sexual_minors).to be_falsey
    expect(moderation.results.first.categories.violence).to be_truthy
    expect(moderation.results.first.categories.violence_graphic).to be_falsey
    expect(moderation.results.first.category_scores.hate).to eql(0.22714105248451233)
    expect(moderation.results.first.category_scores.hate_threatening).to eql(0.4132447838783264)
    expect(moderation.results.first.category_scores.self_harm).to eql(0.005232391878962517)
    expect(moderation.results.first.category_scores.sexual).to eql(0.01407341007143259)
    expect(moderation.results.first.category_scores.sexual_minors).to eql(0.0038522258400917053)
    expect(moderation.results.first.category_scores.violence).to eql(0.9223177433013916)
    expect(moderation.results.first.category_scores.violence_graphic).to eql(0.036865197122097015)
    expect(moderation.results.first.flagged).to be_truthy
  end
end
