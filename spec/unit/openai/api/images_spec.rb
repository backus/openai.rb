# frozen_string_literal: true

RSpec.describe OpenAI::API, '#images' do
  include_context 'an API Resource'

  let(:resource) { api.images }

  let(:sample_image) { OpenAISpec::SPEC_ROOT.join('data/sample_image.png') }

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

  context 'when editing an image' do
    let(:sample_mask) { OpenAISpec::SPEC_ROOT.join('data/sample_image_mask.png') }

    let(:response_body) do
      {
        "created": 1_589_478_378,
        "data": [
          {
            "url": 'https://...'
          },
          {
            "url": 'https://...'
          }
        ]
      }
    end

    it 'can edit an image' do
      image_edit = resource.edit(
        image: sample_image,
        mask: sample_mask,
        prompt: 'Draw a red hat on the person in the image',
        n: 1,
        size: '512x512',
        response_format: 'url',
        user: 'user-123'
      )

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/images/edits',
          hash_including(
            form: hash_including(
              {
                image: instance_of(HTTP::FormData::File),
                mask: instance_of(HTTP::FormData::File),
                prompt: 'Draw a red hat on the person in the image',
                n: 1,
                size: '512x512',
                response_format: 'url',
                user: 'user-123'
              }
            )
          )
        )

      expect(image_edit.created).to eql(1_589_478_378)
      expect(image_edit.data.first.url).to eql('https://...')
    end
  end

  context 'when creating image variations' do
    let(:response_body) do
      {
        "created": 1_589_478_378,
        "data": [
          {
            "url": 'https://...'
          },
          {
            "url": 'https://...'
          }
        ]
      }
    end

    it 'can create image variations' do
      image_variations = resource.create_variation(
        image: sample_image,
        n: 2,
        size: '512x512',
        response_format: 'url',
        user: 'user123'
      )

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/images/variations',
          hash_including(
            form: hash_including(
              {
                image: instance_of(HTTP::FormData::File),
                n: 2,
                size: '512x512',
                response_format: 'url',
                user: 'user123'
              }
            )
          )
        )

      expect(image_variations.created).to eql(1_589_478_378)
      expect(image_variations.data.size).to eql(2)
      expect(image_variations.data.first.url).to eql('https://...')
      expect(image_variations.data.last.url).to eql('https://...')
    end
  end
end
