module Awscr::S3
  private EXCEPTIONS = [
    "BucketAlreadyExists",
    "BucketAlreadyOwnedByYou",
    "NoSuchBucket",
    "NoSuchKey",
    "NoSuchUpload",
    "ObjectAlreadyInActiveTierError",
    "ObjectNotInActiveTierError",
  ]

  # Exception raised when S3 gives us a non 200 http status code. The error
  # will have a specific message from S3.
  class Exception < ::Exception
    # Creates a `ServerError` from an `HTTP::Client::Response`
    def self.from_response(response)
      {% begin %}
        xml = XML.new(response.body || response.body_io)

        code = xml.string("//Error/Code")
        message = xml.string("//Error/Message")

        case code
          {% for error, i in EXCEPTIONS %}
          when {{error}}
            {{error.id}}.new(message)
          {% end %}
        else
          new("#{code}: #{message}")
        end
      {% end %}
    end
  end

  {% for error in EXCEPTIONS %}
    class {{error.id}} < Exception
    end
  {% end %}
end
