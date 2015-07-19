## 0.4.1  (2015-07-19)

- Fixed missing PHP5 package on CentOS 6
- Fixed missing PHP5 package on Precise ([#8](https://github.com/shoekstra/puppet-owncloud/issues/8))
- Fixed old dependency versions ([#13](https://github.com/shoekstra/puppet-owncloud/issues/13), [#16](https://github.com/shoekstra/puppet-owncloud/issues/16))
- Removed support for Debian 6 and Fedora 19 (no longer supported by ownCloud)

## 0.4.0  (2015-03-27)

- Added support for Debian 6, 7, 8
- Fixed Apache HTTP -> HTTPS redirect
- Fixed MySQL database export for RedHat family OSes
- Fixed spec tests to pass when tests are done with FUTURE_PARSER=yes and STRICT_VARIABLES=yes

## 0.3.1  (2015-03-13)

- Fixed puppet-lint `top-scope variable being used without an explicit namespace` warning

## 0.3.0  (2015-03-13)

- Added support for CentOS 6, 7 and Fedora 19, 20
- Added support for Apache 2.4

## 0.2.0  (2015-01-11)

- Added the ability to configure an SSL enabled vhost
- Added `owncloud::database` wrapper to collect exported `mysql::db` resource
- Moved Apache related configuration to `owncloud::apache` to resolve some dependency issues

## 0.1.1  (2014-10-31)

- Corrected puppetlabs-mysql module dependency version
- Fixed exec path
- Fixed puppet-lint scope warnings
- Removed inheritance in classes

## 0.1.0  (2014-08-28)

- First release
