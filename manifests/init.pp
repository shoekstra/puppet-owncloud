# == Class: owncloud
#
# Puppet class to install and configure ownCloud.
#
class owncloud (
  $db_host         = 'localhost',
  $db_name         = 'owncloud',
  $db_pass         = 'owncloud',
  $db_user         = 'owncloud',
  $db_type         = 'mysql',
  $manage_apache   = true,
  $manage_db       = true,
  $manage_repo     = true,
  $manage_skeleton = true,
  $manage_vhost    = true,
  $vhost_https     = true,
  $url             = "owncloud.${::domain}",
  $datadirectory   = $owncloud::params::datadirectory,
) inherits owncloud::params {

  validate_bool($manage_apache)
  validate_bool($manage_db)
  validate_bool($manage_repo)
  validate_bool($manage_skeleton)
  validate_bool($manage_vhost)

  validate_re($db_type, '^mysql$', '$database must be \'mysql\'')

  class { 'owncloud::install': } ->
  class { 'owncloud::config': } ->
  Class['owncloud']
}
