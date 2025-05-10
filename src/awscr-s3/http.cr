require "./responses/*"
require "./paginators/*"
require "uri"

module Awscr::S3
  class Http
    def initialize(
      @signer : Awscr::Signer::Signers::Interface,
      @endpoint : URI,
      @factory : HttpClientFactory = DefaultHttpClientFactory.new,
    )
    end

    # Issue a DELETE request to the *path* with optional *headers*
    #
    # ```
    # http = Http.new(signer)
    # http.delete("/")
    # ```
    def delete(path, headers : Hash(String, String) = Hash(String, String).new)
      puts "\n\n> #{__FILE__}:#{__LINE__} delete"
      puts "  headers = #{headers}"
      headers = HTTP::Headers.new.merge!(headers)
      puts "  headers = #{headers}"
      r = exec("DELETE", path, headers: headers)
      puts "  response = #{r}"
      r
      # rescue ex
      #   STDERR.flush
      #   STDERR.print "#{__FILE__}:#{__LINE__} > delete : Unhandled exception: '#{ex}'\n"
      #   ex.inspect_with_backtrace(STDERR)
      #   STDERR.print "----------------\n"
      #   STDERR.print "  cause: #{ex.cause}" if ex.cause
      #   STDERR.flush
      #   raise ex
    end

    # Issue a POST request to the *path* with optional *headers*, and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.post("/", body: IO::Memory.new("test"))
    # ```
    def post(path, body = nil, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers.new.merge!(headers)
      exec("POST", path, headers: headers, body: body)
    end

    # Issue a PUT request to the *path* with optional *headers* and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.put("/", body: IO::Memory.new("test"))
    # ```
    def put(path : String, body : IO | String | Bytes, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers{"Content-Length" => body.size.to_s}.merge!(headers)
      exec("PUT", path, headers: headers, body: body)
    end

    # Issue a HEAD request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.head("/")
    # ```
    def head(path, headers : Hash(String, String) = Hash(String, String).new)
      exec("HEAD", path, headers: HTTP::Headers.new.merge!(headers))
    end

    # Issue a GET request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.get("/")
    # ```
    def get(path, headers : Hash(String, String) = Hash(String, String).new)
      exec("GET", path, headers: HTTP::Headers.new.merge!(headers))
    end

    # Issue a GET request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.get("/") do |resp|
    #   pp resp
    # end
    # ```
    def get(path, headers : Hash(String, String) = Hash(String, String).new, &)
      exec("GET", path, headers: HTTP::Headers.new.merge!(headers)) do |resp|
        yield resp
      end
    end

    private def exec(method : String, path : String, headers, body = nil)
      STDERR.puts "\n\n> #{__FILE__}:#{__LINE__} exec"
      retries = 0

      loop do
        STDERR.puts " > loop #{retries}"
        client = @factory.acquire_client(@endpoint, @signer)
        STDERR.puts "   client = #{client}"
        STDOUT.flush
        resp = client.exec(method, path, headers, body)
        STDERR.print "#{__FILE__}:#{__LINE__} E:   resp = client.exec (#{resp})\n\n"
        STDERR.puts ""
        STDERR.puts "   resp = #{resp}"
        STDERR.puts "   resp.body = #{resp.body}"
        return handle_response!(resp)
      rescue ex : Awscr::S3::Exception
        raise ex
      rescue ex : IO::Error
        # STDERR.flush
        # STDERR.print "*******************\n"
        # STDERR.print "#{__FILE__}:#{__LINE__} > exec : '#{ex}` '#{ex.target}' '#{ex.target}'\n"
        # STDERR.print "   STDOUT = #{STDOUT}\n"
        # ex.inspect_with_backtrace(STDERR)
        # STDERR.print "----------------\n"
        # STDERR.print "  cause: #{ex.cause}" if ex.cause
        # STDERR.flush
        Awscr::S3::Log.debug exception: ex, &.emit("Could not process a request", retries: retries, method: method, path: path)
        raise ex if retries > 2
        retries += 1
      ensure
        @factory.release(client)
      end
    end

    private def exec(method : String, path : String, headers, body = nil, &)
      puts "\n\n> #{__FILE__}:#{__LINE__} exec(&)"
      retries = 0

      loop do
        client = @factory.acquire_client(@endpoint, @signer)
        return client.exec(method, path, headers, body) do |resp|
          yield handle_response!(resp)
        end
      rescue ex : IO::Error
        STDERR.flush
        STDERR.print "#{__FILE__}:#{__LINE__} > exec(&) : Unhandled exception #{ex.target}: #{ex}"
        ex.inspect_with_backtrace(STDERR)
        STDERR.print "\n\n > cause: #{ex.cause}" if ex.cause
        STDERR.flush
        Awscr::S3::Log.debug exception: ex, &.emit("Could not process a request", retries: retries, method: method, path: path)
        raise ex if retries > 2
        retries += 1
      ensure
        @factory.release(client)
      end
    end

    # :nodoc:
    private def handle_response!(response)
      return response if (200..299).includes?(response.status_code)

      if response.body_io? || !response.body?.try(&.empty?)
        raise S3::Exception.from_response(response)
      else
        raise S3::Exception.new("server error: #{response.status_code}")
      end
    end
  end
end
