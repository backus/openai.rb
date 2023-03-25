# frozen_string_literal: true

RSpec.describe OpenAI, '#images' do
  include_context 'an API Resource'

  let(:resource) { client.images }

  context 'when creating an image' do
    let(:response_body) do
      {
        created: Time.now.to_i,
        data: [
          { url: 'https://example.com/image1.png' },
          { url: 'https://example.com/image2.png' }
        ]
      }
    end

    it 'can create an image generation' do
      image_generation = resource.create(prompt: 'a bird in the forest', size: 512)

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/images/generations',
          hash_including(
            json: hash_including(prompt: 'a bird in the forest', size: 512)
          )
        )

      expect(image_generation.created).to be_within(1).of(Time.now.to_i)
      expect(image_generation.data.map(&:url)).to contain_exactly('https://example.com/image1.png', 'https://example.com/image2.png')
    end
  end
end
