module Awscr::S3::Paginator
  class ListObjectsV2
    include Iterator(Response::ListObjectsV2)

    @last_output : Response::ListObjectsV2?
    @bucket : String

    def initialize(@http : S3::Http, @params : Hash(String, String))
      @params = @params.reject { |_, v| v.nil? || v.empty? }
      @bucket = @params.delete("bucket").as(String)
      @last_output = nil
    end

    def next
      return stop if (lo = @last_output) && !lo.truncated?

      if lo = @last_output
        @params["continuation-token"] = lo.next_token
      end

      @last_output = Response::ListObjectsV2.from_response(next_response)
    end

    private def next_response
      @http.get("/#{@bucket}?#{query_string}")
    end

    private def query_string
      @params.map { |k, v| "#{k}=#{URI.escape(v.to_s)}" }.join("&")
    end
  end
end
