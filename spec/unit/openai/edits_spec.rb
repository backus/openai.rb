# frozen_string_literal: true

RSpec.describe OpenAI, '#edits' do
  include_context 'an API Resource'

  let(:resource) { client.edits }
  let(:response_body) do
    {
      "object": 'edit',
      "created": 1_589_478_378,
      "choices": [
        {
          "text": 'What day of the week is it?',
          "index": 0
        }
      ],
      "usage": {
        "prompt_tokens": 25,
        "completion_tokens": 32,
        "total_tokens": 57
      }
    }
  end

  it 'can create an edit' do
    edit = resource.create(model: 'text-davinci-002',
                           instruction: 'Change "world" to "solar system" in the following text: "Hello, world!"')

    expect(http)
      .to have_received(:post)
      .with('https://api.openai.com/v1/edits', hash_including(:json))

    expect(edit.object).to eql('edit')
    expect(edit.choices.first.text).to eql('What day of the week is it?')
    expect(edit.choices.first.index).to eql(0)
    expect(edit.usage.prompt_tokens).to eql(25)
    expect(edit.usage.completion_tokens).to eql(32)
    expect(edit.usage.total_tokens).to eql(57)
  end
end
