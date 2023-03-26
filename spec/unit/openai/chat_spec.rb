# frozen_string_literal: true

RSpec.describe OpenAI::Chat do
  subject(:chat) do
    described_class.new(
      api: api,
      settings: { model: 'gpt-3.5-turbo' },
      messages: [],
      logger: instance_spy(Logger)
    )
  end
end
