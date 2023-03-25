# frozen_string_literal: true

RSpec.describe OpenAI::Tokenizer do
  let(:tokenizer) { described_class.new }

  it 'can get an encoder by model name' do
    expect(tokenizer.for_model('gpt-4')).to eql(
      OpenAI::Tokenizer::Encoding.new(:cl100k_base)
    )
  end

  it 'can get an encoder by name' do
    expect(tokenizer.get(:cl100k_base)).to eql(
      OpenAI::Tokenizer::Encoding.new(:cl100k_base)
    )
  end

  it 'raises an error if the model name is not valid' do
    expect { tokenizer.for_model('gpt-42') }.to raise_error(
      'Invalid model name or not recognized by Tiktoken: "gpt-42"'
    )
  end

  it 'raises an error if the encoding name is not valid' do
    expect { tokenizer.get('aaaaaaaaaaaa') }.to raise_error(
      'Invalid encoding name or not recognized by Tiktoken: "aaaaaaaaaaaa"'
    )
  end

  it 'can encode text' do
    expect(tokenizer.for_model('gpt-4').encode('Hello, world!')).to eql(
      [9906, 11, 1917, 0]
    )
  end

  it 'can decode tokens' do
    expect(tokenizer.for_model('gpt-4').decode([9906, 11, 1917, 0])).to eql(
      'Hello, world!'
    )
  end

  it 'can count the number of tokens in text' do
    expect(tokenizer.for_model('gpt-4').num_tokens('Hello, world!')).to eql(4)
  end
end
