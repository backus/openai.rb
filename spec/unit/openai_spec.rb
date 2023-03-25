# frozen_string_literal: true

RSpec.describe OpenAI do
  let(:client) { described_class.new('sk-123', http: http) }
  let(:http)   { class_spy(HTTP)                     }

  it 'authenticates requests' do
    client.create_completion(model: 'text-davinci-002', prompt: 'Hello, world!')

    expect(http).to have_received(:headers).with(
      hash_including(
        'Authorization' => 'Bearer sk-123'
      )
    )
  end

  it 'can create a completion' do
  end
end
