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
          location => "http://download.owncloud.org/download/repositories/stable/Debian_${::operatingsystemmajrelease}.0/",
          release  => ' ',
          repos    => '/',
          key      => {
            id     => 'BCECA90325B072AB1245F739AB7C32C35180350A',
            source => "https://download.owncloud.org/download/repositories/stable/Debian_${::operatingsystemmajrelease}.0/Release.key",
          },
          before   => Package[$::owncloud::package_name],
        }
      }
      'Ubuntu': {
        include ::apt

        apt::source { 'owncloud':
          location => "http://download.owncloud.org/download/repositories/stable/Ubuntu_${::operatingsystemrelease}/",
          release  => ' ',
          repos    => '/',
          key      => {
            id     => 'BCECA90325B072AB1245F739AB7C32C35180350A',
            source => "https://download.owncloud.org/download/repositories/stable/Ubuntu_${::operatingsystemrelease}/Release.key",
          },
          before   => Package[$::owncloud::package_name],
        }
      }
      'CentOS': {
        yumrepo { 'owncloud':
          descr    => "ownCloud Server Version stable (CentOS_${::operatingsystemmajrelease})",
          baseurl  => "http://download.owncloud.org/download/repositories/stable/CentOS_${::operatingsystemmajrelease}/",
          gpgcheck => 1,
          gpgkey   => "http://download.owncloud.org/download/repositories/stable/CentOS_${::operatingsystemmajrelease}/repodata/repomd.xml.key",
          enabled  => 1,
          before   => Package[$::owncloud::package_name],
        }
      }
      default: {
      }
    }
  }

  package { $::owncloud::package_name:
    ensure => present,
  }
}
