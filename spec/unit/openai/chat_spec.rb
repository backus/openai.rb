# frozen_string_literal: true

RSpec.describe OpenAI::Chat do
  subject(:chat) do
    described_class.new(
      settings: { model: 'gpt-3.5-turbo' },
      messages: [],
      openai: instance_double(
        OpenAI,
        logger: instance_spy(Logger),
        api: stubbed_api
      )
    )
  end

  let(:api)        { OpenAI::API.new(api_client)                   }
  let(:api_client) { OpenAI::API::Client.new('sk-123', http: http) }

  let(:http) { class_spy(HTTP) }
end
