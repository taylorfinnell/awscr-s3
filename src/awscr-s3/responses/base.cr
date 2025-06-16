require "http"

module Awscr::S3::Response
  # Common functionality for every high-level response wrapper.
  #
  # It stores the raw HTTP status line and headers so callers can
  # inspect retries, rate-limits, etc.  Sub-classes *must* call `super`
  # from their `initialize`.
  abstract class Base
    getter status : HTTP::Status
    getter status_message : String?
    getter headers : HTTP::Headers

    delegate success?, client_error?, server_error?, code, to: status

    def initialize(
      @status : HTTP::Status,
      @status_message : String? = nil,
      @headers : HTTP::Headers = HTTP::Headers.new,
    )
    end

    def self.extract(resp : HTTP::Client::Response)
      new(resp.status, resp.status_message, resp.headers)
    end
  end
end
