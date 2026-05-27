require "./spec_helper"

describe Awscr::S3::PersistentHttpClientFactory do
  it "reuses the same HTTP::Client across requests" do
    WebMock.stub(:get, "https://example.com/a").to_return(status: 200, body: "a")
    WebMock.stub(:get, "https://example.com/b").to_return(status: 200, body: "b")

    signer = PersistentSpec::SpySigner.new
    factory = Awscr::S3::PersistentHttpClientFactory.new
    endpoint = URI.parse("https://example.com")

    client1 = factory.acquire_client(endpoint, signer)
    client2 = factory.acquire_client(endpoint, signer)

    client1.should be(client2)
  end

  it "creates a new client when the endpoint changes" do
    WebMock.stub(:get, "https://a.example.com/").to_return(status: 200, body: "a")
    WebMock.stub(:get, "https://b.example.com/").to_return(status: 200, body: "b")

    signer = PersistentSpec::SpySigner.new
    factory = Awscr::S3::PersistentHttpClientFactory.new

    client1 = factory.acquire_client(URI.parse("https://a.example.com"), signer)
    client2 = factory.acquire_client(URI.parse("https://b.example.com"), signer)

    client1.should_not be(client2)
  end

  it "attaches a signer to the HTTP client" do
    WebMock.stub(:get, "https://example.com/test").to_return(status: 200, body: "ok")

    signer = PersistentSpec::SpySigner.new
    factory = Awscr::S3::PersistentHttpClientFactory.new

    client = factory.acquire_client(URI.parse("https://example.com"), signer)
    response = client.get("/test")

    response.body.should eq "ok"
    signer.called?.should be_true
  end

  it "does not accumulate before_request hooks on reused connections" do
    # Regression test: the parent class's acquire_client calls attach_signer
    # on every invocation. If the persistent factory doesn't override this,
    # each acquire_client adds another before_request hook. After N calls,
    # each request triggers the signer N times — causing S3
    # SignatureDoesNotMatch errors from duplicate Authorization headers.
    signer = PersistentSpec::CountingSigner.new
    factory = Awscr::S3::PersistentHttpClientFactory.new
    endpoint = URI.parse("https://example.com")

    # Acquire the same client 5 times
    5.times { factory.acquire_client(endpoint, signer) }

    # Make a request — the signer's before_request hook should fire exactly once
    WebMock.stub(:get, "https://example.com/test").to_return(status: 200, body: "ok")
    signer.reset_count
    factory.acquire_client(endpoint, signer).get("/test")

    # If hooks accumulated, call_count would be 6 (5 from acquire + 1 for this call)
    signer.call_count.should eq 1
  end
end

module PersistentSpec
  class SpySigner
    include Awscr::Signer::Signers::Interface

    getter? called = false

    def sign(request : HTTP::Request)
      @called = true
    end

    def sign(string : String)
    end

    def presign(request)
    end
  end

  class CountingSigner
    include Awscr::Signer::Signers::Interface

    getter call_count = 0

    def sign(request : HTTP::Request)
      @call_count += 1
    end

    def reset_count
      @call_count = 0
    end

    def sign(string : String)
    end

    def presign(request)
    end
  end
end
