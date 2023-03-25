# frozen_string_literal: true

RSpec.describe OpenAI::API, '#audio' do
  include_context 'an API Resource'

  let(:resource) { api.audio }
  let(:sample_audio) { OpenAISpec::SPEC_ROOT.join('data/sample.mp3') }

  context 'when transcribing audio' do
    let(:response_body) do
      {
        "text": "Imagine the wildest idea that you've ever had, and you're curious about how it might scale to something that's a 100, a 1,000 times bigger. This is a place where you can get to do that."
      }
    end

    it 'can transcribe audio' do
      transcription = resource.transcribe(
        file: sample_audio,
        model: 'model-1234'
      )

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/audio/transcriptions',
          hash_including(
            form: hash_including(
              {
                file: instance_of(HTTP::FormData::File),
                model: 'model-1234'
              }
            )
          )
        )

      expect(transcription.text).to eql("Imagine the wildest idea that you've ever had, and you're curious about how it might scale to something that's a 100, a 1,000 times bigger. This is a place where you can get to do that.")
    end
  end

  context 'when translating audio' do
    let(:sample_audio) { OpenAISpec::SPEC_ROOT.join('data/sample_french.mp3') }

    let(:response_body) do
      {
        "text": 'Hello, my name is Wolfgang and I come from Germany. Where are you heading today?'
      }
    end

    it 'can translate audio' do
      translation = resource.translate(
        file: sample_audio,
        model: 'model-id',
        prompt: 'Hello, my name is Wolfgang and I come from Germany. Where are you heading today?',
        response_format: 'text',
        temperature: 0.5
      )

      expect(http)
        .to have_received(:post)
        .with(
          'https://api.openai.com/v1/audio/translations',
          hash_including(
            form: hash_including(
              {
                file: instance_of(HTTP::FormData::File),
                model: 'model-id',
                prompt: 'Hello, my name is Wolfgang and I come from Germany. Where are you heading today?',
                response_format: 'text',
                temperature: 0.5
              }
            )
          )
        )

      expect(translation.text).to eql('Hello, my name is Wolfgang and I come from Germany. Where are you heading today?')
    end
  end
end
