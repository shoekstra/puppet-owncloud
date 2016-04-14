## Unreleased
### Added
- Options for setting ssl\_cipher and ssl\_protocol Apache settings

## 0.5.2  (2016-03-23)

- Added option to specify admin credentials ([#27](https://github.com/shoekstra/puppet-owncloud/pull/27))
- Added option to specify trusted domains ([#27](https://github.com/shoekstra/puppet-owncloud/pull/27))
- Updated Centos 6/7 repository to now point to https://download.owncloud.org. ([#30](https://github.com/shoekstra/puppet-owncloud/pull/30))
- Updated/Fixed spec tests ([#30](https://github.com/shoekstra/puppet-owncloud/pull/30))

## 0.5.0  (2016-01-02)

- Added `$db_table_prefix parameter`, configures a database table prefix
- Added support for Puppet 4.x
- Added SSL cipers and accepted protocols ([#22](https://github.com/shoekstra/puppet-owncloud/pull/22))
- Increased supported version of [EPEL puppet module](https://github.com/stahnma/puppet-module-epel)
- Installs PHP MySQL bindings using the [PuppetLabs MySQL puppet module](https://github.com/puppetlabs/puppetlabs-mysql) if `$manage_phpmysql` is `true` ([#14](https://github.com/shoekstra/puppet-owncloud/iss
ues/14))
- Removes default vhost (000-default.conf) on Debian-based systems if `$manage_apache` is `true`

## 0.4.3  (2015-12-13)

- Fix compilation errors on CentOS systems

## 0.4.2  (2015-12-13)

- Install owncloud-server instead of owncloud, removes Apache dependency ([#21](https://github.com/shoekstra/puppet-owncloud/pull/21))
- Fixed puppet-lint warning

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
