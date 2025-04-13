# Changelog

## [Unreleased]

### Chores

- Add release and fix CI badges to README. (#135, thanks @treagod)
- Support Crystal 1.16. (#136, thanks @miry)

## [0.9.0] - 2025-04-12

### Added

- Add option to include port in presigned url. (#106, thanks @taylorfinnell)
- Adds option to specify scheme for presigned urls. (#110, thanks @taylorfinnell)
- Add support for session key to use temporary accounts. (#114, thanks @anton7c3)
- Support upload of big files. (#112, thanks @joseafga)
- Setup Logging. (#122, thanks @miry)
- ci: Validate examples in CI pipeline. (#123, thanks @miry)
- Use Presigned URL for Minio and DigitalOcean Spaces. (#124, thanks @miry)
- Setup the integration tests. (#126, thanks @miry)

### Fixed

- Fixed an overflow when files were listed that are above 2G. (#116, thanks @philipp-classen)
- Fix Awscr::S3::Response::HeadObjectOutput.meta method. (#111 and #128, thanks @compumike and @miry)
- fixed: retries needs to be incremented to avoid infinite retries. (#129, thanks @philipp-classen)

### Changed

- Migrating more code to use the new session key API. (#115, thanks @philipp-classen)
- Bump awscr-signer to v0.9.0. (#120, thanks @miry)

## [0.8.3] - 2021-09-16

### Changed

- Switch from Travis-CI to GitHub Workflows. (#98, thanks @OldhamMade)
- Use Github CI status badge. (#101, thanks @caspiano)

### Added

- Adds `Awscr::S3::Client#copy_object(bucket, source, destination, headers)`. (#100, thanks @caspiano)

[Unreleased]: https://github.com/taylorfinnell/awscr-s3/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/taylorfinnell/awscr-s3/compare/v0.8.3...v0.9.0
[0.8.3]: https://github.com/taylorfinnell/awscr-s3/compare/v0.8.2...v0.8.3
