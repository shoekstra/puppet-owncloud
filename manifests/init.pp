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
  $manage_phpmysql = true,
  $manage_repo     = true,
  $manage_skeleton = true,
  $manage_vhost    = true,
  $ssl             = false,
  $ssl_ca          = undef,
  $ssl_cert        = undef,
  $ssl_chain       = undef,
  $ssl_key         = undef,
  $ssl_cipher      = 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
  $ssl_protocol    = 'all -SSLv2 -SSLv3',
  $trusted_domains = '',
  $url             = "owncloud.${::domain}",
  $datadirectory   = $::owncloud::params::datadirectory,
) inherits ::owncloud::params {

  validate_bool($manage_apache)
  validate_bool($manage_db)
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

  class { '::owncloud::install': } ->
  class { '::owncloud::apache': } ->
  class { '::owncloud::config': } ->
  Class['::owncloud']
}

