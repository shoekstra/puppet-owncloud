# == Class owncloud::config
#
# This class is called from owncloud for service config.
#
class owncloud::config {

  exec { "mkdir -p ${::owncloud::datadirectory}":
    path   => ['/bin', '/usr/bin'],
    unless => "test -d ${::owncloud::datadirectory}"
  }

  file { $::owncloud::datadirectory:
    ensure  => directory,
    owner   => $::owncloud::www_user,
    group   => $::owncloud::www_user,
    mode    => '0770',
    require => Exec["mkdir -p ${::owncloud::datadirectory}"],
  }

  if $::owncloud::manage_db {
    if $::owncloud::db_type == 'mysql' {
      if $::owncloud::db_host == 'localhost' {
        mysql::db { $::owncloud::db_name:
          user     => $::owncloud::db_user,
          password => $::owncloud::db_pass,
          host     => $::owncloud::db_host,
          grant    => ['all'],
        }
      } else {
        @@mysql::db { $::owncloud::db_name:
          user     => $::owncloud::db_user,
          password => $::owncloud::db_pass,
          host     => $::ipaddress_eth0,
          grant    => ['all'],
          tag      => 'owncloud',
        }
      }
    }
  }

  # Template uses:
  $db_host = $::owncloud::db_host
  $db_name = $::owncloud::db_name
  $db_pass = $::owncloud::db_pass
  $db_user = $::owncloud::db_user
  $db_type = $::owncloud::db_type
  $datadirectory = $::owncloud::datadirectory

  file { "${::owncloud::documentroot}/config/autoconfig.php":
    ensure  => present,
    owner   => $::owncloud::www_user,
    group   => $::owncloud::www_group,
    content => template('owncloud/autoconfig.php.erb'),
  }

  if $::owncloud::manage_skeleton {
    file { [
      "${::owncloud::documentroot}/core/skeleton/documents",
      "${::owncloud::documentroot}/core/skeleton/music",
      "${::owncloud::documentroot}/core/skeleton/photos",
      ]:
      ensure  => directory,
      recurse => true,
      purge   => true,
    }
  }
}
