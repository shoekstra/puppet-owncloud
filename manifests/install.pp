# == Class owncloud::install
#
class owncloud::install {

  if $owncloud::manage_apache {
    class { '::apache':
      mpm_module        => 'prefork',
      purge_configs     => true,
      before            => Package[$owncloud::package_name],
      default_vhost     => false,
      default_ssl_vhost => false,
    }
    class { '::apache::mod::php': }
    class { '::apache::mod::rewrite': }
    class { '::apache::mod::ssl': }
  }

  if $owncloud::manage_repo {
    case $::operatingsystem {
      'Ubuntu': {
        apt::source { $owncloud::package_name:
          location    => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_${::operatingsystemrelease}/",
          release     => '',
          repos       => '/',
          include_src => false,
          key         => 'BA684223',
          key_source  => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_${::operatingsystemrelease}/Release.key",
          before      => Package[$owncloud::package_name],
        }
      }
      default: {
        fail("${module_name} unsupported operatingsystem ${::operatingsystem}")
      }
    }
  }
  if $owncloud::manage_apache or $owncloud::manage_vhost {

    $vhost_custom_fragment = "
    <Directory \"${owncloud::documentroot}\">
      Options Indexes FollowSymLinks MultiViews
      AllowOverride All
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
      apache::vhost { 'owncloud-https':
        servername      => $owncloud::url,
        port            => 443,
        docroot         => $owncloud::documentroot,
        # for some reason the directories has no effect, use custom fragment instead.
        directories => [
          {
            path           => $owncloud::documentroot,
            provider       => 'directory',
            allow          => 'from all',
            allow_override => 'All',
            satisfy        => 'Any',
            #dav            => 'off',
            options         => ['Indexes','FollowSymLinks','MultiViews']
          },
        ],
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

  package { $owncloud::package_name:
    ensure => present,
  }
}
