require "./spec_helper"
require "http/server"

describe Awscr::S3::DefaultHttpClientFactory do
  describe "#release" do
    it "closes the HTTP client to prevent TCP connection leaks", tags: "integration" do
      server = HTTP::Server.new do |context|
        context.response.content_type = "text/plain"
        context.response.print "ok"
      end
      address = server.bind_tcp("127.0.0.1", 0)
      spawn { server.listen }

      begin
        factory = Awscr::S3::DefaultHttpClientFactory.new
        endpoint = URI.parse("http://127.0.0.1:#{address.port}")
        client = factory.acquire_raw_client(endpoint)

        # Make a request to establish a TCP connection
        response = client.get("/")
        response.body.should eq "ok"

        # Connection is open — @io holds the active socket
        client.@io.should_not be_nil

        # release() should close the connection
        factory.release(client)

        # After release, the connection should be closed.
        # Without this fix, release() is a no-op and the TCP connection
        # remains open. When the server eventually closes its end, the
        # socket enters CLOSE_WAIT and stays there indefinitely — leaking
        # one connection per S3 request in long-running processes.
        client.@io.should be_nil
      ensure
        server.close
      end
    end

    it "handles nil client gracefully" do
      factory = Awscr::S3::DefaultHttpClientFactory.new
      factory.release(nil)
    end
  end
end
