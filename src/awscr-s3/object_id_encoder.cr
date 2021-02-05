module Awscr::S3
  # An object on S3
  module ObjectIdEncoder
    def self.encode(object_id : String) : String
      String.build do |io|
        URI.encode(object_id, io, space_to_plus: true) do |byte|
          # check for characters we want to encode
          # otherwise fall back to default implementation
          # https://github.com/crystal-lang/crystal/blob/5999ae29beacf4cfd54e232ca83c1a46b79f26a5/src/uri/encoding.cr#L70-L72
          !should_encode?(byte) && (URI.reserved?(byte) || URI.unreserved?(byte))
        end
      end
    end

    private def self.should_encode?(byte)
      char = byte.unsafe_chr
      char == '=' || char == '\''
    end
  end
end
