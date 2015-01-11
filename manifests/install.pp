# == Class owncloud::install
#
class owncloud::install {

  if $owncloud::manage_repo {
    case $::operatingsystem {
      'Ubuntu': {
        apt::source { 'owncloud':
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
      }
    }
  }

  package { $owncloud::package_name:
    ensure => present,
  }
}
