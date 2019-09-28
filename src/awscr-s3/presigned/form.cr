require "http"
require "http/client"
require "uuid"
require "./post"

module Awscr
  module S3
    module Presigned
      class Form
        @client : HTTP::Client
        @boundary : String

        # Create a new `Form`
        #
        # Building a `Form`
        #
        # ```
        # Awscr::S3::Presigned::Form.build("us-east-1", "aws key", "aws secret") do |form|
        #   form.expiration(Time.unix(Time.local.to_unix + 1000))
        #   form.condition("bucket", "my bucket")
        #   form.condition("acl", "public-read")
        #   form.condition("key", "helloworld.png")
        #   form.condition("Content-Type", "image/png")
        #   form.condition("success_action_status", "201")
        # end
        # ```
        def self.build(region, aws_access_key, aws_secret_key, signer = :v4, &block)
          post = Post.new(region, aws_access_key, aws_secret_key, signer)
          post.build do |p|
            yield p
          end
          new(post, HTTP::Client.new(URI.parse(post.url)))
        end

        # Create a form with a Post object and an IO.
        def initialize(@post : Post, client : HTTP::Client)
          @boundary = UUID.random.to_s
          @client = client
        end

        # Submit the `Form`.
        def submit(io : IO)
          @client.post("/", headers, body(io).to_s)
        end

        # Represent this `Presigned::Form` as raw HTML.
        def to_html
          HtmlPrinter.new(self)
        end

        # The url of the form.
        def url
          @post.url
        end

        # The fields of the form.
        def fields
          @post.fields
        end

        # :nodoc:
        private def headers
          HTTP::Headers{"Content-Type" => %(multipart/form-data; boundary="#{@boundary}")}
        end

        # :nodoc:
        private def body(io : IO)
          body_io = IO::Memory.new
          HTTP::FormData.build(body_io, @boundary) do |form|
            @post.fields.each do |field|
              form.field(field.key, field.value)
            end
            form.file("file", io)
          end
          body_io
        end
      end
    end
  end
end
