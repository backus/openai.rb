# frozen_string_literal: true

require 'pathname'
require 'logger'

require 'concord'
require 'anima'
require 'abstract_type'
require 'http'
require 'addressable'
require 'ice_nine'
require 'tiktoken_ruby'

require 'openai/util'
require 'openai/tokenizer'
require 'openai/chat'
require 'openai/api'
require 'openai/api/cache'
require 'openai/api/client'
require 'openai/api/resource'
require 'openai/api/response'
require 'openai/version'

class OpenAI
  include Concord.new(:api_client, :logger)

  public :logger

  ROOT = Pathname.new(__dir__).parent.expand_path.freeze

  def self.create(api_key, cache: nil, organization: nil, logger: Logger.new('/dev/null'))
    client = API::Client.new(api_key, organization_id: organization)

    if cache.is_a?(Pathname) && cache.directory?
      client = API::Cache.new(
        client,
        API::Cache::Strategy::FileSystem.new(cache)
      )
    end

    new(client, logger)
  end

  # @api private
  def self.build(api_client, logger)
    new(api_client, logger)
  end

  private_class_method :new

  def without_cache
    self.class.build(api_client.without_cache, logger)
  end

  def api
    API.new(api_client)
  end

  def tokenizer
    Tokenizer.new
  end
  alias tokens tokenizer

  def chat(model:, history: [], **kwargs)
    Chat.new(
      openai: self,
      settings: kwargs.merge(model: model),
      messages: history
    )
  end
end
