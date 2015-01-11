0.2.0  (2015-01-11)

- Added the ability to configure an SSL enabled vhost.
- Added `owncloud::database` wrapper to collect exported `mysql::db` resource.
- Moved Apache related configuration to `owncloud::apache` to resolve some dependency issues.

0.1.1  (2014-10-31)

- Added basic acceptance tests for Ubuntu 12.04 and 14.04
- Corrected puppetlabs-mysql module dependency version
- Fixed exec path
- Fixed puppet-lint scope warnings
- Removed inheritance in classes.

0.1.0  (2014-08-28)

- First release.
