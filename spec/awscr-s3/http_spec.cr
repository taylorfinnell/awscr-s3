require "../spec_helper"

module Awscr::S3
  SIGNER = Awscr::Signer::Signers::V4.new("blah", "blah", "blah", "blah")

  ERROR_BODY = <<-BODY
    <?xml version="1.0" encoding="UTF-8"?>
    <Error>
      <Code>NoSuchKey</Code>
      <Message>The resource you requested does not exist</Message>
      <Resource>/mybucket/myfoto.jpg</Resource> 
      <RequestId>4442587FB7D0A2F9</RequestId>
    </Error>
  BODY

  describe Http do
    describe "initialize" do
      it "sets the correct host" do
        WebMock.stub(:get, "http://s3.amazonaws.com/")
               .to_return(status: 200)

        http = Http.new(SIGNER)

        http.get("/").status_code.should eq 200
      end

      it "sets the correct host with a defined region" do
        WebMock.stub(:get, "http://s3-eu-west-1.amazonaws.com/")
               .to_return(status: 200)

        http = Http.new(SIGNER, "eu-west-1")

        http.get("/").status_code.should eq 200
      end
    end

    describe "get" do
      it "handles aws specific errors" do
        WebMock.stub(:get, "http://s3.amazonaws.com/sup?")
               .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError, "NoSuchKey: The resource you requested does not exist" do
          http.get("/sup")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:get, "http://s3.amazonaws.com/?")
               .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError do
          http.get("/sup")
        end
      end
    end

    describe "head" do
      it "handles aws specific errors" do
        WebMock.stub(:head, "http://s3.amazonaws.com/?")
               .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError, "NoSuchKey: The resource you requested does not exist" do
          http.head("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:head, "http://s3.amazonaws.com/?")
               .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError do
          http.head("/")
        end
      end
    end

    describe "put" do
      it "handles aws specific errors" do
        WebMock.stub(:put, "http://s3.amazonaws.com/?")
               .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError, "NoSuchKey: The resource you requested does not exist" do
          http.put("/", "")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:put, "http://s3.amazonaws.com/?")
               .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError do
          http.put("/", "")
        end
      end
    end

    describe "post" do
      it "handles aws specific errors" do
        WebMock.stub(:post, "http://s3.amazonaws.com/?")
               .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError, "NoSuchKey: The resource you requested does not exist" do
          http.post("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:post, "http://s3.amazonaws.com/?")
               .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError do
          http.post("/")
        end
      end
    end

    describe "delete" do
      it "handles aws specific errors" do
        WebMock.stub(:delete, "http://s3.amazonaws.com/?")
               .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError, "NoSuchKey: The resource you requested does not exist" do
          http.delete("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:delete, "http://s3.amazonaws.com/?")
               .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises Http::ServerError do
          http.delete("/")
        end
      end
    end
  end
end
