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
          location => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Debian_${::operatingsystemmajrelease}.0/",
          release  => ' ',
          repos    => '/',
          key      => {
            id     => 'F9EA4996747310AE79474F44977C43A8BA684223',
            source => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Debian_${::operatingsystemmajrelease}.0/Release.key",
          },
          before   => Package[$::owncloud::package_name],
        }
      }
      'Ubuntu': {
        include ::apt

        if $::lsbdistcodename == 'precise' {
          apt::ppa { 'ppa:ondrej/php5-oldstable':
            before => Package[$::owncloud::package_name],
          }
        }

        apt::source { 'owncloud':
          location => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_${::operatingsystemrelease}/",
          release  => ' ',
          repos    => '/',
          key      => {
            id     => 'F9EA4996747310AE79474F44977C43A8BA684223',
            source => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_${::operatingsystemrelease}/Release.key",
          },
          before   => Package[$::owncloud::package_name],
        }
      }
      'CentOS': {
        include ::epel

        if $::operatingsystemmajrelease == '6' {
          include ::remi

          yumrepo { 'remi-php56':
            name       => 'remi-php56',
            descr      => 'Les RPM de remi de PHP 5.6 pour Enterprise Linux 6 - $basearch',
            baseurl    => absent,
            mirrorlist => 'http://rpms.famillecollet.com/enterprise/6/php56/mirror',
            gpgcheck   => 1,
            gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-remi',
            enabled    => 1,
            before     => Package[$::owncloud::package_name],
            require    => Class['::remi']
          }
        }

        yumrepo { 'isv:ownCloud:community':
          name     => 'isv_ownCloud_community',
          descr    => "Latest stable community release of ownCloud (CentOS_CentOS-${::operatingsystemmajrelease})",
          baseurl  => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/CentOS_CentOS-${::operatingsystemmajrelease}/",
          gpgcheck => 1,
          gpgkey   => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/CentOS_CentOS-${::operatingsystemmajrelease}/repodata/repomd.xml.key",
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

  package { $::owncloud::package_name:
    ensure => present,
  }
  
  if $::owncloud::package_name_phpmysql {
	package { $::owncloud::package_name_phpmysql:
		ensure => present,
	}
  }
}
