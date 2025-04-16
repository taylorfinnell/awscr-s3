module Awscr::S3
  # Abstract factory for providing configured `HTTP::Client` instances used to
  # communicate with AWS S3. This allows different implementations to manage
  # client lifecycle — such as creating a new client per request, reusing a persistent
  # connection, or implementing client pooling.
  abstract class HttpClientFactory
    # Acquires a configured `HTTP::Client` for the given endpoint and signer.
    #
    # Implementations must return an `HTTP::Client` that is ready to be used
    # for making signed HTTP requests to AWS services.
    abstract def acquire_client(endpoint : URI, signer : Signers::Interface) : HTTP::Client

    # Releases the given HTTP client. This is called when the client is no longer needed.
    def release(client : HTTP::Client?)
      # No-op
    end
  end
end
