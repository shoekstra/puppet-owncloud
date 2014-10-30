# == Class owncloud::config
#
# This class is called from owncloud
#
class owncloud::config inherits owncloud {

  if $manage_apache or $manage_vhost {
    require '::apache::mod::php'
    require '::apache::mod::rewrite'
    require '::apache::mod::ssl'

    $vhost_custom_fragment = "
    <Directory \"${documentroot}\">
      Options Indexes FollowSymLinks MultiViews
      AllowOverride None
      Order allow,deny
      Allow from all
      Satisfy Any
      Dav Off
    </Directory>"

    apache::vhost { 'owncloud-http':
      servername      => $url,
      port            => 80,
      docroot         => $documentroot,
      custom_fragment => $vhost_custom_fragment,
    }
  }

  exec { "mkdir -p ${datadirectory}":
    path   => ['/bin', '/usr/bin'],
    unless => "test -d ${datadirectory}"
  } ->

  file { $datadirectory:
    ensure => directory,
    owner  => $www_user,
    group  => $www_user,
    mode   => 0770,
  }

  if $manage_db {
    if $db_type == 'mysql' {
      if $db_host == 'localhost' {
        mysql::db { $db_name:
          user     => $db_user,
          password => $db_pass,
          host     => $db_host,
          grant    => ['all'],
        }
      } else {
        @@mysql::db { $db_name:
          user     => $db_user,
          password => $db_pass,
          host     => $::ipaddress_eth0,
          grant    => ['all'],
          tag      => 'owncloud',
        }
      }
    }
  }

  file { "${documentroot}/config/autoconfig.php":
    ensure  => present,
    owner   => $www_user,
    group   => $www_group,
    content => template('owncloud/autoconfig.php.erb'),
  }

  if $manage_skeleton {
    file { [
      "${documentroot}/core/skeleton/documents",
      "${documentroot}/core/skeleton/music",
      "${documentroot}/core/skeleton/photos",
      ]:
      ensure  => directory,
      recurse => true,
      purge   => true,
    }
  }
}
