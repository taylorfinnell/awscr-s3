module Awscr::S3
  # Abstract factory for providing configured `HTTP::Client` instances used to
  # communicate with AWS S3. This allows different implementations to manage
  # client lifecycle — such as creating a new client per request, reusing a persistent
  # connection, or implementing client pooling.
  abstract class HttpClientFactory
    # Acquires a fully configured `HTTP::Client`, with the signer attached.
    #
    # Calls `acquire_raw_client` internally to retrieve a client and automatically
    # attaches a signing hook using the provided `signer`.
    #
    # Override this method if you need custom logic beyond standard signing.
    def acquire_client(endpoint : URI, signer : Awscr::Signer::Signers::Interface) : HTTP::Client
      client = acquire_raw_client(endpoint)
      attach_signer(client, signer)
      client
    end

    # Acquires a raw `HTTP::Client` for the given `endpoint` and `signer`.
    #
    # Subclasses must implement this method to construct or retrieve a client instance.
    # The returned client is not expected to have a signing hook attached yet.
    abstract def acquire_raw_client(endpoint : URI) : HTTP::Client

    # Releases the given HTTP client. This is called when the client is no longer needed.
    def release(client : HTTP::Client?)
      # No-op
    end

    protected def attach_signer(client, signer)
      if signer.is_a?(Awscr::Signer::Signers::V4)
        client.before_request { |req| signer.as(Awscr::Signer::Signers::V4).sign(req, encode_path: false) }
      else
        client.before_request { |req| signer.sign(req) }
      end
    end
  end
end
