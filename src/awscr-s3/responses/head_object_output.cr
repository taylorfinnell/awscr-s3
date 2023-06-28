module Awscr::S3::Response
  class HeadObjectOutput
    DATE_FORMAT = "%a, %d %b %Y %H:%M:%S %Z"

    # The body of the request object
    getter status : HTTP::Status
    getter status_message : String | Nil
    getter headers : HTTP::Headers

    # Create a `GetObjectOutput` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response : HTTP::Client::Response)
      new(
        status: response.status,
        status_message: response.status_message,
        headers: response.headers
      )
    end

    def initialize(@status, @status_message, @headers)
    end

    {% for f in ["Cache-Control", "Content-Disposition", "Content-Encoding", "Content-Language", "Content-Type"] %}
      def {{ f.id.stringify.underscore.gsub(/-/, "_").id }} : String?
        headers["{{ f.id }}"]?
      end
    {% end %}

    def last_modified : Time
      parse_date(headers["Last-Modified"])
    end

    def size : UInt64
      headers["Content-Length"].to_u64
    end

    def etag : String?
      headers["ETag"].try { |v| v.strip('"') }
    end

    def meta : Hash(String, String)
      meta = {} of String => String
      headers.each do |k, v|
        next unless k.starts_with?("x-amz-meta-")
        meta[k.lchop("x-amz-meta-")] = v.first
      end
      meta
    end

    private def parse_date(date : String)
      Time.parse!(date.gsub(/\s{2,}/, ' '), DATE_FORMAT)
    end
  end
end
