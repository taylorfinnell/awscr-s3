require "../spec_helper"

module Awscr::S3
  describe Http do
    describe "ServerError" do
      describe "from_response" do
        it "makes a reasonable error from http response" do
          body = <<-BODY
          <?xml version="1.0" encoding="UTF-8"?>
          <Error>
            <Code>NoSuchKey</Code>
            <Message>The resource you requested does not exist</Message>
            <Resource>/mybucket/myfoto.jpg</Resource> 
            <RequestId>4442587FB7D0A2F9</RequestId>
          </Error>
          BODY

          resp = HTTP::Client::Response.new(200, body)

          err = Http::ServerError.from_response(resp)

          err.message.should eq("NoSuchKey: The resource you requested does not exist")
        end
      end
    end
  end
end
 
