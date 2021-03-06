require_relative 'spec_helper'

if ENV['TEST_INTEGRATION']
  describe Rack::Attack::Cache do
    def delete(key)
      if @cache.store.respond_to?(:delete)
        @cache.store.delete(key)
      else
        @cache.store.del(key)
      end
    end

    require 'active_support/cache/dalli_store'
    require 'active_support/cache/redis_store'
    cache_stores = [
      ActiveSupport::Cache::MemoryStore.new,
      ActiveSupport::Cache::DalliStore.new("localhost"),
      ActiveSupport::Cache::RedisStore.new("localhost"),
      Redis::Store.new
    ]

    cache_stores.each do |store|
      describe "with #{store.class}" do

        before {
          @cache ||= Rack::Attack::Cache.new
          @key = "rack::attack:cache-test-key"
          @expires_in = 1
          @cache.store = store
          delete(@key)
        }

        after { delete(@key) }

        describe "do_count once" do
          it "should be 1" do
            @cache.send(:do_count, @key, @expires_in).must_equal 1
          end
        end

        describe "do_count twice" do
          it "must be 2" do
            @cache.send(:do_count, @key, @expires_in)
            @cache.send(:do_count, @key, @expires_in).must_equal 2
          end
        end
        describe "do_count after expires_in" do
          it "must be 1" do
            @cache.send(:do_count, @key, @expires_in)
            sleep @expires_in # sigh
            @cache.send(:do_count, @key, @expires_in).must_equal 1
          end
        end
      end

    end

  end
else
  puts 'Skipping cache store integration tests (set ENV["TEST_INTEGRATION"] to enable)'
end
