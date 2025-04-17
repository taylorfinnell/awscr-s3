require "./http_client_factory"

module Awscr::S3
  # The default implementation of `HttpClientFactory` used to provide HTTP clients
  # for communicating with S3. This factory creates a new `HTTP::Client` instance
  # for each request.
  class DefaultHttpClientFactory < HttpClientFactory
    # Acquires a new `HTTP::Client` instance configured for the given endpoint and signer.
    def acquire_raw_client(endpoint : URI) : HTTP::Client
      HTTP::Client.new(endpoint)
    end
  end
end
