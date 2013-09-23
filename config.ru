require './flatmap'

if (memcache_servers = ENV["MEMCACHE_SERVERS"])
  use Rack::Cache,
    verbose: true,
    metastore:   "memcached://#{memcache_servers}",
    entitystore: "memcached://#{memcache_servers}"
#else
#  use Rack::Cache,
#    verbose: true,
#    metastore:   "memcached://127.0.0.1",
#    entitystore: "memcached://127.0.0.1"
end

run Sinatra::Application