# frozen_string_literal: true

RSpec.describe OpenAI::Response do
  it 'can parse a JSON response'

  it 'exposes the original payload'

  describe '.field' do
    it 'exposes the field'
    it 'can expose fields under a different name than the key path'
    it 'wraps the field if a wrapper is provided'
    it 'wraps each element in a the wrapper if the value is an array'
    it 'raises an error if the field is not present'
  end

  describe '.optional_field' do
  end
end
