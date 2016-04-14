# == Class: owncloud
#
# Puppet class to install and configure ownCloud.
#
class owncloud (
  $admin_pass      = '',
  $admin_user      = '',
  $db_host         = 'localhost',
  $db_name         = 'owncloud',
  $db_table_prefix = '',
  $db_pass         = 'owncloud',
  $db_user         = 'owncloud',
  $db_type         = 'mysql',
  $http_port       = 80,
  $https_port      = 443,
  $manage_apache   = true,
  $manage_db       = true,
  $manage_package  = true,
  $manage_phpmysql = true,
  $manage_repo     = true,
  $manage_skeleton = true,
  $manage_vhost    = true,
  $ssl             = false,
  $ssl_ca          = undef,
  $ssl_cert        = undef,
  $ssl_chain       = undef,
  $ssl_key         = undef,
  $trusted_domains = '',
  $url             = "owncloud.${::domain}",
  $datadirectory   = $::owncloud::params::datadirectory,
) inherits ::owncloud::params {

  validate_bool($manage_apache)
  validate_bool($manage_db)
  validate_bool($manage_package)
  validate_bool($manage_repo)
  validate_bool($manage_skeleton)
  validate_bool($manage_vhost)
  validate_bool($ssl)

  validate_re($db_type, '^mysql$', '$database must be \'mysql\'')

  if $ssl {
    validate_absolute_path($ssl_cert, $ssl_key)

    if $ssl_ca { validate_absolute_path($ssl_ca) }
    if $ssl_chain { validate_absolute_path($ssl_chain) }
  }

  # If we're not managing the package, we probably don't need to
  # manage the repository
  unless $manage_package {
    $manage_repo = false
  }

  class { '::owncloud::install': } ->
  class { '::owncloud::apache': } ->
  class { '::owncloud::config': } ->
  Class['::owncloud']
}

