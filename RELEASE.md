# Release

## Before You Begin

Ensure your local workstation is configured to be able to [Sign commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits).

## Local Preparation

### Sync with `master`

Make sure local and remote state are sync:

```shell
git checkout master
git pull origin master
git push origin master
```

### Run Tests & Format Code

Make sure all test pass and docs are updated

```shell
crystal spec
crystal tool format
```

Validate that all examples still work:

```shell
for example in examples/*.cr; do
  crystal run $example
done
```

### Bump Version & Update Docs

- Update the [CHANGELOG.md](CHANGELOG.md)
  - Add a new version header under `## [Unreleased]`.
  - Move the changes from `Unreleased` to the new version section.
  - Update the comparison links at the bottom of the file.
- Update the version in:
  - [shard.yml](shard.yml)
  - [src/awscr-s3/version.cr](src/awscr-s3/version.cr)

### Create a Signed Release Commit and Tag

```shell
export RELEASE_VERSION="vX.Y.Z"

git commit -a -S -m "Release ${RELEASE_VERSION}"
git tag -s "$RELEASE_VERSION" # Use changelog text as the tag message

Ensure the signing key is published and verifiable before pushing:

```shell
gpg --keyserver hkps://keys.openpgp.org --send-keys <KEY_ID>
```

Confirm the key can be retrieved and the tag verifies in a clean keyring:

```shell
rm -rf /tmp/verify-gnupg && mkdir -p /tmp/verify-gnupg
GNUPGHOME=/tmp/verify-gnupg gpg --keyserver hkps://keys.openpgp.org --recv-keys <KEY_ID>
GNUPGHOME=/tmp/verify-gnupg git tag -v "$RELEASE_VERSION"
```
```

### Push Changes

```shell
git push origin master --follow-tags
```

## Verify Release

- GitHub Actions should automatically build and publish the release.
- Verify the release appears on the [Release gets created in Github](https://github.com/taylorfinnell/awscr-s3/releases).
- Confirm that the tag and release notes match the latest entry in the changelog.

### Alternative: Manual GitHub Release

If needed, create a release manually:

- **Tag name:** `vX.Y.Z`
- **Title:** Same as the tag name (e.g. `v0.1.3`)
- **Description:** Copy from the relevant changelog entry
