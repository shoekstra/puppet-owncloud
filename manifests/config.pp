# == Class owncloud::config
#
# This class is called from owncloud
#
class owncloud::config {

  if $owncloud::manage_apache or $owncloud::manage_vhost {
    require '::apache::mod::php'
    require '::apache::mod::rewrite'
    require '::apache::mod::ssl'

    $vhost_custom_fragment = "
    <Directory \"${owncloud::documentroot}\">
      Options Indexes FollowSymLinks MultiViews
      AllowOverride None
      Order allow,deny
      Allow from all
      Satisfy Any
      Dav Off
    </Directory>"

    if $owncloud::vhost_https {
      $cert = '/etc/ssl/owncloud-https.cert'
      $key  = '/etc/ssl/owncloud-https.key'

      file { $cert :
        ensure  => file,
        source  => "puppet:///modules/owncloud/sslcert.pem",
        owner   => 'www-data'
      }
      file { $key :
        ensure  => file,
        source  => "puppet:///modules/owncloud/sslkey.pem",
        owner   => 'www-data',
        mode    => '400'
      }
      apache::vhost { $owncloud::url:
        servername      => $owncloud::url,
        port            => 443,
        docroot         => $owncloud::documentroot,
        ssl             => true,
        ssl_cert        => $cert,
        ssl_key         => $key,
        require         => File [ $cert, $key ],
        custom_fragment => $vhost_custom_fragment,
      }
    } else {
      apache::vhost { 'owncloud-http':
        servername      => $owncloud::url,
        port            => 80,
        docroot         => $owncloud::documentroot,
        custom_fragment => $vhost_custom_fragment,
      }
    }
  }

  exec { "mkdir -p ${owncloud::datadirectory}":
    path   => ['/bin', '/usr/bin'],
    unless => "test -d ${owncloud::datadirectory}"
  } ->

  file { $owncloud::datadirectory:
    ensure => directory,
    owner  => $owncloud::www_user,
    group  => $owncloud::www_user,
    mode   => '0770',
  }

  if $owncloud::manage_db {
    if $owncloud::db_type == 'mysql' {
      if $owncloud::db_host == 'localhost' {
        mysql::db { $owncloud::db_name:
          user     => $owncloud::db_user,
          password => $owncloud::db_pass,
          host     => $owncloud::db_host,
          grant    => ['all'],
        }
      } else {
        @@mysql::db { $owncloud::db_name:
          user     => $owncloud::db_user,
          password => $owncloud::db_pass,
          host     => $::ipaddress_eth0,
          grant    => ['all'],
          tag      => 'owncloud',
        }
      }
    }
  }

  file { "${owncloud::documentroot}/config/autoconfig.php":
    ensure  => present,
    owner   => $owncloud::www_user,
    group   => $owncloud::www_group,
    content => template('owncloud/autoconfig.php.erb'),
  }

  if $owncloud::manage_skeleton {
    file { [
      "${owncloud::documentroot}/core/skeleton/documents",
      "${owncloud::documentroot}/core/skeleton/music",
      "${owncloud::documentroot}/core/skeleton/photos",
      ]:
      ensure  => directory,
      recurse => true,
      purge   => true,
    }
  }
}
