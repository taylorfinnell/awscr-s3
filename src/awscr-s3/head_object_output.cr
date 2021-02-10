module Awscr::S3::Response
  class HeadObjectOutput
    DATE_FORMAT = "%a, %d %b %Y %H:%M:%S %Z"

    # The body of the request object
    getter status : HTTP::Status
    getter status_message : String | Nil
    getter headers : HTTP::Headers
    getter content_type : String
    getter last_modified : Time
    getter size : UInt64

    # Create a `GetObjectOutput` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      new(
        status: response.status,
        status_message: response.status_message,
        headers: response.headers,
        content_type: response.headers["Content-Type"],
        last_modified: self.parse_date(response.headers["Last-Modified"]),
        size: response.headers["Content-Length"].to_u64,
      )
    end

    def initialize(@status, @status_message, @headers, @content_type, @last_modified, @size)
    end

    private def self.parse_date(date : String)
      Time.parse!(date.gsub(/\s{2,}/, ' '), DATE_FORMAT)
    end
  end
end
