module Fixtures
  def self.start_multipart_upload_response(bucket = "bucket", key = "object", upload_id = "FxtGq8otGhDtYJa5VYLpPOBQo2niM2a1YR8wgcwqHJ1F1Djflj339mEfpm7NbYOoIg.6bIPeXl2RB82LuAnUkTQUEz_ReIu2wOwawGc0Z4SLERxoXospqANXDazuDmRF")
    <<-RESP
      <?xml version="1.0" encoding="UTF-8"?>
      <InitiateMultipartUploadResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
        <Bucket>#{bucket}</Bucket>
        <Key>#{key}</Key>
        <UploadId>#{upload_id}</UploadId>
      </InitiateMultipartUploadResult>
    RESP
  end

  def self.complete_multipart_upload_response
    <<-RESP_BODY
      <?xml version="1.0" encoding="UTF-8"?>
        <CompleteMultipartUploadResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
        <Location>https://s3.amazonaws.com/screensnapr-development/test</Location>
        <Bucket>screensnapr-development</Bucket>
        <Key>test</Key>
        <ETag>"7611c6414e4b58f22ff9f59a2c1767b7-2"</ETag>
      </CompleteMultipartUploadResult>
    RESP_BODY
  end
end
