module Awscr::S3::Paginator
  class ListObjectsV2
    include Iterator(Response::ListObjectsV2)

    @last_output : Response::ListObjectsV2?
    @bucket : String

    def initialize(@http : S3::Http, @params : Hash(String, String?))
      @params = @params.reject { |_, v| v.nil? || v.empty? }
      @bucket = @params.delete("bucket").as(String)
      @last_output = nil
    end

    def next
      if @last_output && @last_output.not_nil!.truncated? == false
        stop
      else
        @params["continuation-token"] = @last_output.not_nil!.next_token if @last_output

        @last_output = Response::ListObjectsV2.from_xml(next_response.body)
      end
    end

    private def next_response
      @http.get("/#{@bucket}?#{query_string}")
    end

    private def query_string
      @params.map { |k, v| "#{k}=#{URI.escape(v.to_s)}" }.join("&")
    end
  end
end
