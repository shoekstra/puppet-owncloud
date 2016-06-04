# == Class owncloud::params
#
# This class is meant to be called from owncloud.
# It sets variables according to platform.
#
class owncloud::params {
  case $::osfamily {
    'Debian': {
      case $::operatingsystem {
        'Debian', 'Ubuntu': {
          $datadirectory = '/var/www/owncloud/data'
          $documentroot  = '/var/www/owncloud'
          $package_name  = 'owncloud-files'
          $www_user      = 'www-data'
          $www_group     = 'www-data'

          if ($::operatingsystem == 'Debian' and versioncmp($::operatingsystemrelease, '6') <= 0) {
            fail("${::operatingsystem} ${::operatingsystemrelease} not supported")
          }

          if ($::operatingsystem == 'Debian' and versioncmp($::operatingsystemrelease, '8') >= 0) or ($::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '13.10') >= 0)  {
            $apache_version = '2.4'
          } else {
            $apache_version = '2.2'
          }
        }
        default: {
          fail("${::operatingsystem} not supported")
        }
      }
    }
    'RedHat': {
      case $::operatingsystem {
        'CentOS': {
          $datadirectory = '/var/www/html/owncloud/data'
          $documentroot  = '/var/www/html/owncloud'
          $package_name  = 'owncloud-files'
          $www_user      = 'apache'
          $www_group     = 'apache'

          if (versioncmp($::operatingsystemrelease, '7') >= 0) {
            $apache_version = '2.4'
          } else {
            $apache_version = '2.2'
          }
        }
        default: {
          fail("${::operatingsystem} not supported")
        }
      }
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
