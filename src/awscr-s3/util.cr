module Awscr::S3
  module Util
    def self.encode(object_id : String) : String
      String.build do |io|
        URI.encode(object_id, io) { |byte| URI.unreserved?(byte) || byte.chr == '/' || byte.chr == '~' }
      end
    end
  end
end
