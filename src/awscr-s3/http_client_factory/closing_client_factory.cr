require "./http_client_factory"

module Awscr::S3
  # An `HttpClientFactory` that creates a new `HTTP::Client` per request
  # (like `DefaultHttpClientFactory`) but **explicitly closes** the client
  # in `release` instead of abandoning it for GC finalization.
  #
  # This prevents the memory leak from accumulated OpenSSL buffers while
  # remaining safe for concurrent use by multiple fibers sharing the same
  # `S3::Client` instance.
  class ClosingHttpClientFactory < HttpClientFactory
    def acquire_raw_client(endpoint : URI) : HTTP::Client
      HTTP::Client.new(endpoint)
    end

    def release(client : HTTP::Client?)
      client.try(&.close) rescue nil
    end
  end
end
