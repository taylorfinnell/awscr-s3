require "./http_client_factory"

module Awscr::S3
  # The default implementation of `HttpClientFactory` used to provide HTTP clients
  # for communicating with S3. This factory creates a new `HTTP::Client` instance
  # for each request and closes it after use.
  class DefaultHttpClientFactory < HttpClientFactory
    # Acquires a new `HTTP::Client` instance configured for the given endpoint and signer.
    def acquire_raw_client(endpoint : URI) : HTTP::Client
      HTTP::Client.new(endpoint)
    end

    # Closes the HTTP client to release the underlying TCP connection.
    #
    # Without this, each S3 request leaks a keep-alive TCP connection.
    # In long-running processes, these accumulate as CLOSE_WAIT sockets
    # when the server closes its end, eventually exhausting memory.
    def release(client : HTTP::Client?)
      client.try &.close
    end
  end
end
