require "./spec_helper"

class HttpClientFactoryMock < Awscr::S3::HttpClientFactory
  getter acquired_count = 0
  getter released_count = 0

  def acquire_raw_client(endpoint : URI) : HTTP::Client
    @acquired_count += 1
    HTTP::Client.new(endpoint)
  end

  def release(client : HTTP::Client?)
    @released_count += 1
  end
end
