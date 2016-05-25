# == Class owncloud::install
#
# This class is called from owncloud for install.
#
class owncloud::install {

  if $::owncloud::manage_repo {
    case $::operatingsystem {
      'Debian': {
        include ::apt

        apt::source { 'owncloud':
        location  => "http://download.owncloud.org/download/repositories/stable/${::operatingsystem}_${::operatingsystemmajrelease}/",
          release => ' ',
          repos   => '/',
          key     => {
            id     => 'BCECA90325B072AB1245F739AB7C32C35180350A',
            source => "http://download.owncloud.org/download/repositories/stable/${::operatingsystem}_${::operatingsystemmajrelease}/Release.key",
          },
          before  => Package[$::owncloud::package_name],
        }
      }
      'Ubuntu': {
        include ::apt

        apt::source { 'owncloud':
        location  => "http://download.owncloud.org/download/repositories/stable/${::operatingsystem}_${::operatingsystemrelease}/",
          release => ' ',
          repos   => '/',
          key     => {
            id     => 'BCECA90325B072AB1245F739AB7C32C35180350A',
            source => "http://download.owncloud.org/download/repositories/stable/${::operatingsystem}_${::operatingsystemrelease}/Release.key",
          },
          before  => Package[$::owncloud::package_name],
        }
      }
      'CentOS': {
        include ::epel

        if $::operatingsystemmajrelease == '6' {
          include ::remi
        }

        yumrepo { 'isv:ownCloud:community':
          name     => 'isv_ownCloud_community',
          descr    => "ownCloud Server Version stable (CentOS_${::operatingsystemmajrelease})",
          baseurl  => "https://download.owncloud.org/download/repositories/stable/CentOS_${::operatingsystemmajrelease}/",
          gpgcheck => 1,
          gpgkey   => "https://download.owncloud.org/download/repositories/stable/CentOS_${::operatingsystemmajrelease}/repodata/repomd.xml.key",
          enabled  => 1,
          before   => Package[$::owncloud::package_name],
        }
      }
      'Fedora': {
        yumrepo { 'isv:ownCloud:community':
          name     => 'isv_ownCloud_community',
          descr    => "Latest stable community release of ownCloud (Fedora_${::operatingsystemmajrelease})",
          baseurl  => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Fedora_${::operatingsystemmajrelease}/",
          gpgcheck => 1,
          gpgkey   => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Fedora_${::operatingsystemmajrelease}/repodata/repomd.xml.key",
          enabled  => 1,
          before   => Package[$::owncloud::package_name],
        }
      }
      default: {
      }
    }
  }

  if $::owncloud::manage_phpmysql {
    class { '::mysql::bindings':
      php_enable => true,
      before     => Package[$::owncloud::package_name],
    }
  }

  package { $::owncloud::package_name:
    ensure => present,
  }
}
