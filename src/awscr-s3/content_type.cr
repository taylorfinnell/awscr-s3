require "mime"

module Awscr::S3
  # Determines the Content-Type of IO
  class ContentType
    # The default content type if one can not be determined from the filename
    DEFAULT = "binary/octet-stream"

    # Gets a content type based on the file extesion, if there is no file
    # extension it uses the default content type
    def self.get(io : IO) : String
      if io.responds_to?(:path)
        io.path.try { |path| MIME.from_filename(path, DEFAULT) } || DEFAULT
      else
        DEFAULT
      end
    end
  end
end
