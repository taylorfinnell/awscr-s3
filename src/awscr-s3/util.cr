module Awscr::S3
  module Util
    # Remove --exclude-warnings=spec/awscr-s3/util_spec.cr from scripts/run_batched_specs on removal
    @[Deprecated("Use URI.encode_path instead")]
    def self.encode(object_id : String) : String
      String.build do |io|
        URI.encode(object_id, io) { |byte| URI.unreserved?(byte) || byte.chr == '/' || byte.chr == '~' }
      end
    end
  end
end
