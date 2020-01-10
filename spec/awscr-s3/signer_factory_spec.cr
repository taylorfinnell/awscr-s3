require "../spec_helper"

module Awscr::S3
  describe SignerFactory do
    it "can return v2 signers" do
      signer = SignerFactory.get("region", "key", "secrety", version: :v2)
      signer.should be_a(Awscr::Signer::Signers::V2)
    end

    it "can return v4 signers" do
      signer = SignerFactory.get("region", "key", "secrety", version: :v4)
      signer.should be_a(Awscr::Signer::Signers::V4)
    end

    it "raises on invalid version" do
      expect_raises(S3::Exception) do
        SignerFactory.get("region", "key", "secrety", version: :v1)
      end
    end
  end
end
