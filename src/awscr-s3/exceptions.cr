module Awscr::S3
  private EXCEPTIONS = %w(
    AccountProblem
    AllAccessDisabled
    AmbiguousGrantByEmailAddress
    BadDigest
    BucketAlreadyExists
    BucketAlreadyOwnedByYou
    BucketNotEmpty
    CredentialsNotSupported
    CrossLocationLoggingProhibited
    EntityTooSmall
    EntityTooLarge
    ExpiredToken
    IllegalVersioningConfigurationException
    IncompleteBody
    IncorrectNumberOfFilesInPostRequest
    InlineDataTooLarge
    InternalError
    InvalidAccessKeyId
    InvalidAddressingHeader
    InvalidArgument
    InvalidBucketName
    InvalidBucketState
    InvalidDigest
    InvalidEncryptionAlgorithmError
    InvalidLocationConstraint
    InvalidObjectState
    InvalidPart
    InvalidPartOrder
    InvalidPayer
    InvalidPolicyDocument
    InvalidRange
    InvalidRequest
    InvalidSecurity
    InvalidSOAPRequest
    InvalidStorageClass
    InvalidTargetBucketForLogging
    InvalidToken
    InvalidURI
    KeyTooLongError
    MalformedACLError
    MalformedPOSTRequest
    MalformedXML
    MaxMessageLengthExceeded
    MaxPostPreDataLengthExceededError
    MetadataTooLarge
    MethodNotAllowed
    MissingAttachment
    MissingContentLength
    MissingRequestBodyError
    MissingSecurityElement
    MissingSecurityHeader
    NoLoggingStatusForKey
    NoSuchBucket
    NoSuchBucketPolicy
    NoSuchKey
    NoSuchLifecycleConfiguration
    NoSuchUpload
    NoSuchVersion
    NotImplemented
    NotSignedUp
    OperationAborted
    PermanentRedirect
    PreconditionFailed
    Redirect
    RestoreAlreadyInProgress
    RequestIsNotMultiPartContent
    RequestTimeout
    RequestTimeTooSkewed
    RequestTorrentOfBucketError
    ServerSideEncryptionConfigurationNotFoundError
    ServiceUnavailable
    SignatureDoesNotMatch
    SlowDown
    TemporaryRedirect
    TokenRefreshRequired
    TooManyBuckets
    UnexpectedContent
    UnresolvableGrantByEmailAddress
    UserKeyMustBeSpecified)

  # Exception raised when S3 gives us a non 200 http status code. The error
  # will have a specific message from S3.
  class Exception < ::Exception
    # Creates a `S3::Exception` from an `HTTP::Client::Response`
    def self.from_response(response)
      {% begin %}
        xml = XML.new(response.body || response.body_io)

        code = xml.string("//Error/Code")
        message = xml.string("//Error/Message")

        case code
          {% for error, i in EXCEPTIONS %}
          when {{error}}
            {{error.id}}.new(message)
          {% end %}
        else
          new("#{code}: #{message}")
        end
      {% end %}
    end
  end

  {% for error in EXCEPTIONS %}
    # :nodoc:
    class {{error.id}} < Exception
    end
  {% end %}
end
