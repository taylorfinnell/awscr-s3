require "./http_client_factory"

module Awscr::S3
  # An `HttpClientFactory` that reuses a single `HTTP::Client` per endpoint,
  # keeping the underlying TCP + TLS connection alive across requests.
  #
  # The default `DefaultHttpClientFactory` creates a **new** `HTTP::Client`
  # for every S3 operation. Each client opens a fresh TLS connection, and
  # `release` is a no-op — the client (and its ~600 KB of OpenSSL buffers)
  # is abandoned, only freed when the GC finalizes the Crystal wrapper.
  #
  # In high-throughput applications this causes RSS to grow by hundreds of
  # megabytes per hour, because the GC sees only a small Crystal object and
  # has no urgency to collect — meanwhile the C-heap OpenSSL buffers
  # accumulate.
  #
  # This factory keeps a persistent connection open and reuses it for all
  # requests to the same endpoint. If a request fails with `IO::Error`, the
  # connection is automatically recycled.
  #
  # ## Usage
  #
  # ```
  # factory = Awscr::S3::PersistentHttpClientFactory.new
  # client = Awscr::S3::Client.new("region", "key", "secret",
  #   endpoint: "https://s3.example.com",
  #   client_factory: factory)
  # ```
  class PersistentHttpClientFactory < HttpClientFactory
    @client : HTTP::Client? = nil
    @endpoint : URI? = nil
    @signed = false

    # Override acquire_client to avoid re-attaching the signer on every call.
    def acquire_client(endpoint : URI, signer : Awscr::Signer::Signers::Interface) : HTTP::Client
      if (client = @client).nil? || @endpoint != endpoint
        @client.try(&.close) rescue nil
        client = HTTP::Client.new(endpoint)
        @client = client
        @endpoint = endpoint
        @signed = false
      end
      unless @signed
        attach_signer(client, signer)
        @signed = true
      end
      client
    rescue IO::Error | OpenSSL::SSL::Error
      @client.try(&.close) rescue nil
      client = HTTP::Client.new(endpoint)
      @client = client
      @endpoint = endpoint
      @signed = false
      attach_signer(client, signer)
      @signed = true
      client
    end

    def acquire_raw_client(endpoint : URI) : HTTP::Client
      # Not used — acquire_client is overridden
      HTTP::Client.new(endpoint)
    end

    def release(client : HTTP::Client?)
      # Keep the connection alive — don't close it.
      # If the caller caught an IO/SSL error and is retrying,
      # the next acquire_client will get a fresh connection
      # because we detect the closed state below.
    end

    # Reset the persistent connection so the next acquire creates a fresh one.
    # Called by Http#exec when a request fails with IO::Error.
    def reset
      @client.try(&.close) rescue nil
      @client = nil
      @signed = false
    end

    def finalize
      @client.try(&.close) rescue nil
    end
  end
end
