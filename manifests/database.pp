# == Class owncloud::database
#
# This class is called from owncloud
#
class owncloud::database {

  Mysql::Db <<| tag == 'owncloud' |>>

}
