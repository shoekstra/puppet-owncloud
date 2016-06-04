# == Class owncloud::php
#
# This class is called from owncloud.
#
class owncloud::php {

  if $::owncloud::manage_php {
    class { '::php':
      service => 'httpd'
    }

    php::module { ['gd', 'ldap']: }

    case $::osfamily {
      'Debian': {
        php::module { ['curl', 'mysqlnd']: }
      }
      'RedHat': {
        php::module { ['mbstring', 'mysql', 'pdo', 'process', 'xml']: }
      }
      default: {
      }
    }

    if $::owncloud::php_modules {
      php::module { $::owncloud::php_modules: }
    }

    Class['::php'] -> Php::Module <| |>
  }
}
