require "../src/awscr-s3"
require "http"

class PoolingHttpClientFactory < Awscr::S3::HttpClientFactory
  getter pool : Array(HTTP::Client)
  @created_count : Int32 = 0

  def initialize(@pool_size : Int32 = 3)
    @pool = [] of HTTP::Client
  end

  def acquire_raw_client(endpoint : URI) : HTTP::Client
    if @pool.size > 0
      @pool.pop.not_nil!
    elsif @created_count < @pool_size
      @created_count += 1
      HTTP::Client.new(endpoint)
    else
      raise "No available clients in pool (limit of #{@pool_size} reached)"
    end
  end

  def release(client : HTTP::Client?)
    return unless client
    @pool << client
  end
end

client = Awscr::S3::Client.new(
  "unused",
  "key",
  "secret",
  endpoint: "http://127.0.0.1:9000",
  client_factory: PoolingHttpClientFactory.new,
)
