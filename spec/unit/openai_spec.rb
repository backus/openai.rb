# frozen_string_literal: true

RSpec.describe OpenAI do
  include_context 'an API Resource'

  let(:resource) { api.completions }

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

  context 'when the request is not 2xx' do
    let(:response_body) do
      {
        "error": {
          "message": "You didn't provide an API key.",
          "type": 'invalid_request_error',
          "param": nil,
          "code": nil
        }
      }
    end

    let(:response_status_code) { 401 }

    it 'raises an error' do
      expect { resource.create(model: 'text-davinci-002', prompt: 'Hello, world!') }
        .to raise_error(OpenAI::API::Error, <<~ERROR)
          Unexpected response status! Expected 2xx but got: 401 Unauthorized

          Body:

          #{response.body}
        ERROR
    end

    it 'includes the original HTTP response as an attribute on the error instance' do
      resource.create(model: 'text-davinci-002', prompt: 'Hello, world!')
    rescue OpenAI::API::Error => e
      expect(e.http_response).to be(response)
    end
  end
end
