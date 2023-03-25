# frozen_string_literal: true

RSpec.describe OpenAI::API::Cache do
  let(:cached_client) do
    described_class.new(client, cache_strategy)
  end

  let(:client) do
    instance_double(OpenAI::API::Client, api_key: 'sk-123').tap do |double|
      %i[get post post_form_multipart delete].each do |method|
        allow(double).to receive(method).and_return(api_resource)
      end
    end
  end

  let(:api_resource) do
    JSON.dump(text: 'Wow neat')
  end

  let(:cache_strategy) do
    described_class::Strategy::Memory.new
  end

  it 'wraps the public API of API::Client' do
    client_public_api =
      OpenAI::API::Client.public_instance_methods(false) - %i[api_key inspect]

    client_public_api.each do |client_method|
      expect(cached_client).to respond_to(client_method)
    end
  end

  it 'can cache get requests' do
    cached_client.get('/v1/foo')
    cached_client.get('/v1/foo')
    cached_client.get('/v1/bar')

    expect(client).to have_received(:get).with('/v1/foo').once
    expect(client).to have_received(:get).with('/v1/bar').once
  end

  it 'can cache JSON post requests' do
    cached_client.post('/v1/foo', model: 'model1', prompt: 'prompt1')                # miss
    cached_client.post('/v1/foo', model: 'model1', prompt: 'prompt1')                # hit
    cached_client.post('/v1/foo', model: 'model1', prompt: 'prompt2')                # miss
    cached_client.post('/v1/bar', model: 'model1', prompt: 'prompt2')                # miss
    cached_client.post_form_multipart('/v1/foo', model: 'model1', prompt: 'prompt1') # miss

    expect(client).to have_received(:post).thrice
    expect(client).to have_received(:post_form_multipart).once
  end

  it 'does not cache delete requests' do
    cached_client.delete('/v1/foo')
    cached_client.delete('/v1/foo')

    expect(client).to have_received(:delete).twice
  end

  it 'can cache multipart form post requests' do
    cached_client.post_form_multipart('/v1/foo', model: 'model1', prompt: 'prompt1') # miss
    cached_client.post_form_multipart('/v1/foo', model: 'model1', prompt: 'prompt1') # hit
    cached_client.post_form_multipart('/v1/foo', model: 'model1', prompt: 'prompt2') # miss
    cached_client.post_form_multipart('/v1/bar', model: 'model1', prompt: 'prompt2') # miss
    cached_client.post('/v1/foo', model: 'model1', prompt: 'prompt1')                # miss

    expect(client).to have_received(:post_form_multipart).thrice
  end

  it 'writes unique and somewhat human readable cache keys' do
    expect(cache_strategy.cached?('get_foo_9bfe1439')).to be(false)
    cached_client.get('/v1/foo')
    expect(cache_strategy.cached?('get_foo_9bfe1439')).to be(true)
  end

  it 'returns identical values for cache hits and misses' do
    miss = cached_client.get('/v1/foo')
    hit  = cached_client.get('/v1/foo')

    expect(miss).to eq(hit)
  end

  context 'when the API key changes' do
    before do
      allow(client).to receive(:api_key).and_return('sk-123', 'sk-123', 'sk-456')
    end

    it 'factors the API key into the cache calculation' do
      cached_client.get('/v1/foo')
      cached_client.get('/v1/foo')
      cached_client.get('/v1/foo')

      expect(client).to have_received(:get).with('/v1/foo').twice
    end
  end

  context 'when using the filesystem cache strategy' do
    let(:cache_strategy) do
      described_class::Strategy::FileSystem.new(cache_dir)
    end

    let(:cache_dir) do
      Pathname.new(Dir.mktmpdir)
    end

    it 'writes JSON files' do
      cache_path = cache_dir.join('get_foo_9bfe1439.json')
      expect(cache_path.exist?).to be(false)
      cached_client.get('/v1/foo')
      expect(cache_path.exist?).to be(true)

      expect(cache_strategy.read('get_foo_9bfe1439')).to eq(api_resource)
    end
  end
end
