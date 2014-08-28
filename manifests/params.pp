# == Class owncloud::params
#
# This class is meant to be called from owncloud
# It sets variables according to platform
#
class owncloud::params {
  case $::operatingsystem {
    'Ubuntu': {
      $datadirectory = '/var/www/owncloud/data'
      $documentroot  = '/var/www/owncloud'
      $package_name  = 'owncloud'
      $service_name  = 'owncloud'
      $www_user      = 'www-data'
      $www_group     = 'www-data'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
