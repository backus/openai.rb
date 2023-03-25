# frozen_string_literal: true

RSpec.describe OpenAI do
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

  it 'authenticates requests' do
    resource.create(model: 'text-davinci-002', prompt: 'Hello, world!')

    expect(http).to have_received(:headers).with(
      hash_including(
        'Authorization' => 'Bearer sk-123'
      )
    )
  end
end
