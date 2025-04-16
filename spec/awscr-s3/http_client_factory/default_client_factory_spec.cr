require "./spec_helper"

describe Awscr::S3::DefaultHttpClientFactory do
  it "attaches a signer to the HTTP client" do
    WebMock.stub(:get, "https://example.com/test").to_return(status: 200, body: "ok")

    signer = Awscr::S3::DefaultHttpClientFactorySpec::SpySigner.new
    factory = Awscr::S3::DefaultHttpClientFactory.new

    client = factory.acquire_client(URI.parse("https://example.com"), signer)

    response = client.get("/test")
    response.body.should eq "ok"

    signer.called.should be_true
  end
end

module Awscr::S3::DefaultHttpClientFactorySpec
  class SpySigner
    include Awscr::Signer::Signers::Interface

    getter called = false

    def sign(request : HTTP::Request)
      @called = true
    end

    def sign(string : String)
      # unused in this test
    end

    def presign(request)
      # unused in this test
    end
  end
end
