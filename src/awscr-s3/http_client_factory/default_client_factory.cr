require "./http_client_factory"

module Awscr::S3
  # The default implementation of `HttpClientFactory` used to provide HTTP clients
  # for communicating with S3. This factory creates a new `HTTP::Client` instance
  # for each request.
  class DefaultHttpClientFactory < HttpClientFactory
    # Acquires a new `HTTP::Client` instance configured for the given endpoint and signer.
    def acquire_client(endpoint : URI, signer : Awscr::Signer::Signers::Interface) : HTTP::Client
      client = HTTP::Client.new(endpoint)
      attach_signer(client, signer)
      client
    end

    private def attach_signer(client, signer)
      if signer.is_a?(Awscr::Signer::Signers::V4)
        client.before_request { |req| signer.as(Awscr::Signer::Signers::V4).sign(req, encode_path: false) }
      else
        client.before_request { |req| signer.sign(req) }
      end
    end
  end
end
