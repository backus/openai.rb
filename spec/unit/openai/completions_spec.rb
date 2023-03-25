# frozen_string_literal: true

RSpec.describe OpenAI, '#completions' do
  include_context 'an API Resource'

  let(:resource) { client.completions }

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
end
