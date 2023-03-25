# frozen_string_literal: true

class OpenAI
  class API
    class Cache
      include Concord.new(:client, :cache)

      def get(route)
        read_cache_or_apply(verb: :get, route: route) do
          client.get(route)
        end
      end

      # Caching is a no-op for delete requests since caching a delete does
      # not really make sense
      def delete(...)
        client.delete(...)
      end

      def post(route, **body)
        read_cache_or_apply(verb: :post, route: route, body: body, format: :json) do
          client.post(route, **body)
        end
      end

      def post_form_multipart(route, **body)
        read_cache_or_apply(verb: :post, route: route, body: body, format: :form) do
          client.post_form_multipart(route, **body)
        end
      end

      private

      def read_cache_or_apply(...)
        target = cache_target(...).unique_id

        if cache.cached?(target)
          cache.read(target)
        else
          yield.tap do |result|
            cache.write(target, result)
          end
        end
      end

      def cache_target(verb:, route:, body: nil, format: nil)
        Target.new(
          verb: verb,
          api_key: client.api_key,
          route: route,
          body: body,
          format: format
        )
      end

      class Target
        include Anima.new(:verb, :api_key, :route, :body, :format)
        include Memoizable

        def unique_id
          serialized = JSON.dump(serialize_for_cache)
          digest = Digest::SHA256.hexdigest(serialized)
          bare_route = route.delete_prefix('/v1/')
          prefix = "#{verb}_#{bare_route}".gsub('/', '_')
          fingerprint = digest.slice(0, 8)

          "#{prefix}_#{fingerprint}"
        end
        memoize :unique_id

        def serialize_for_cache
          data = to_h
          if data[:body]
            data[:body] = data[:body].transform_values do |value|
              if value.instance_of?(HTTP::FormData::File)
                Digest::SHA256.hexdigest(value.to_s)
              else
                value
              end
            end
          end
          data
        end
      end

      class Strategy
        include AbstractType

        abstract_method :cached?
        abstract_method :read
        abstract_method :write

        class Memory < self
          include Concord.new(:cache)

          def initialize
            super({})
          end

          def cached?(target)
            cache.key?(target)
          end

          def write(target, result)
            cache[target] = result
          end

          def read(target)
            cache.fetch(target)
          end
        end

        class FileSystem < self
          include Concord.new(:cache_dir)

          def cached?(target)
            cache_file(target).file?
          end

          def write(target, result)
            cache_file(target).write(result)
          end

          def read(target)
            cache_file(target).read
          end

          private

          def cache_file(target)
            cache_dir.join("#{target}.json")
          end
        end
      end
    end
  end
end
