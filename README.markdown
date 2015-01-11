[![Build Status](https://travis-ci.org/shoekstra/puppet-owncloud.svg?branch=develop)](https://travis-ci.org/shoekstra/puppet-owncloud)
[![Puppet Forge](http://img.shields.io/puppetforge/v/shoekstra/owncloud.svg)](https://forge.puppetlabs.com/shoekstra/owncloud)

ownCloud
========

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with ownCloud](#setup)
    * [What ownCloud affects](#what-owncloud-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with ownCloud](#beginning-with-owncloud)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

The ownCloud module eases installation and initial configuration of ownCloud.

## Module Description

ownCloud is a software system for what is commonly termed "file hosting" and is very similar to the widely-used Dropbox, with the primary difference being that ownCloud is free and open-source, allowing anyone to install and operate it without charge on a private server.

This module provides a simple way to deploy an ownCloud instance, optionally including Apache installation and virtual host configuration, database creation, and an autoconfigured ownCloud instance ready for you to log into. It preconfigures the ownCloud instance using the [automatic configuration method](http://doc.owncloud.org/server/7.0/admin_manual/configuration/configuration_automation.html "Defining Automatic Configuration").

## Setup

### What owncloud affects

* ownCloud configuration files and directories
* package/service/configuration files for Apache
* Apache modules and virtual hosts
* MySQL database and user creation (does not install a MySQL server)

    * **WARNING**: If module is set to manage Apache (enabled by default), any Apache configurations that are *not* managed by Puppet will be purged.

### Setup Requirements

In order to use the [PuppetLabs MySQL module](https://github.com/puppetlabs/puppetlabs-mysql) to create the database on a separate database server, you will need to have [exported resources functionality](https://docs.puppetlabs.com/puppet/latest/reference/lang_exported.html "Exported Resources").

If Apache is not installed, the default behaviour of the ownCloud module is to install it.

### Beginning with ownCloud

To install ownCloud with the default parameters:

```puppet
    class { 'owncloud': }
```

The defaults are determined by your operating system (e.g. Debian systems have one set of defaults, and RedHat systems have another). These defaults will work well in a testing environment, but are not suggested for production as they result in:

* An 'owncloud' database and user being created (password 'owncloud')
* Apache installed, with a default vhost of "owncloud.$::domain"
* ownCloud configured to use MySQL as the database backend (does not install a MySQL server)
* ownCloud data directory (where user files are kept) located at $documentroot/data (this should be moved out of the document root before being put on the Internet)

#### Install on a single server

To install ownCloud on a single server, (using the [PuppetLabs MySQL module](https://github.com/puppetlabs/puppetlabs-mysql) to install MySQL and create a 'owncloud' database):

```puppet
    class { '::mysql::server':
      override_options => {
        'mysqld' => { 'bind-address' => '0.0.0.0' }
      },
      restart       => true,
      root_password => 'sup3rt0ps3cr3t',
    }

    class { '::owncloud':
      db_user => 'owncloud',
      db_pass => 'p4ssw0rd',
    }
```

#### Install on separate database and web servers

To install ownCloud on a web server with a separate MySQL database server, on your web server:

```puppet
    class { '::owncloud':
      db_host => 'mysqlserver.local',
      db_name => 'owncloud',
      db_user => 'owncloud',
      db_pass => 'p4ssw0rd',
    }
```

When $db_host is not set to 'localhost', the web server will export any mysql:db resources for a database server to collect. To collect these exported databases, include the following simple wrapper class on your MySQL server:

```puppet
    include '::owncloud::database'
```

The ownCloud module does not install or configure the database server itself, this would need to be deployed by manually or, for example, with something similar to:

```puppet
    class { '::mysql::server':
      override_options => {
        'mysqld' => { 'bind-address' => '0.0.0.0' }
      },
      restart       => true,
      root_password => 'sup3rt0ps3cr3t',
    }
```

#### Install and manage only ownCloud

To install and configure ownCloud with no additional modules:

```puppet
    class { '::owncloud':
      manage_apache => false,
      manage_db     => false,
      manage_vhost  => false,
    }
```

Deploying your web server with this configuration will result in:

* ownCloud repository added to your system
* ownCloud package installed (with any absent dependencies, such as Apache, PHP modules, etc.)
* ownCloud auto configured and ready for access on http://$default_vhost/owncloud

## Usage

### The `owncloud` class

The `owncloud` class configures all possible options for this module. With all functionality enabled, it will
* create the required database (either locally or publish the `mysql::db` resource to be collected later).
* install the Apache vhost.
* deploy ownCloud using the autoconfigure method.

#### Parameters

##### `datadirectory`

Sets the directory user data will be stored in. It is not recommended to keep this in the default location (as a sub directory of the application document root) and it should be moved out of the document root before making your ownCloud instance accessible via the internet. Defaults to '/var/www/owncloud/data' on Ubuntu

##### `db_host`

Sets the database server that ownCloud should use. If this is not 'localhost' and `manage_db` is set to true, the module will publish the `mysql:db` resource for collection by another node (typically your database server, collecting with `Mysql::Db <<| tag == 'owncloud' |>>`, if using the [PuppetLabs MySQL module](https://github.com/puppetlabs/puppetlabs-mysql)). Defaults to 'localhost'.

##### `db_name`

Set the database name in the ownCloud configuration and the database to create if `manage_db` is set to true. Defaults to 'owncloud'.

##### `db_user`

Set the database user in the ownCloud configuration and the database user to create (using `db_pass` as the password) if `manage_db` is set to true. Defaults to 'owncloud'.

##### `db_pass`

Set the database user in the ownCloud configuration. Defaults to 'owncloud'.

##### `db_type`

Set the database type in the ownCloud configuration. Currently the only supported backend database is MySQL. Defaults to 'mysql'.

##### `manage_apache`

Set to true for the module to install Apache and virtual host using the [PuppetLabs Apache module](https://github.com/puppetlabs/puppetlabs-apache). Typically this is managed elsewhere in your node definition, but if you are installing ownCloud on a dedicated webserver then setting `manage_apache` to true will configure Apache as required. Defaults to 'true'.

##### `manage_db`

Set to true for the module to create the database and database user for you, using the `db_name`, `db_user`, `db_pass` and `db_type` values. Enabling this will not install the database server, this must be done separately. Defaults to 'true'.

##### `manage_repo`

Set to true for the module to install the official ownCloud repository. Defaults to 'true'.

##### `manage_skeleton`

Set to true for the module to manage the skeleton directory. This is could be a feature in the future, but for the moment this removes the demo files from the skeleton directory in `${documentroot}/core/skeleton/{documents,music,photo}`. Defaults to 'true'.

##### `manage_vhost`

Set to true for the module to install the Apache virtual host using the [PuppetLabs Apache module](https://github.com/puppetlabs/puppetlabs-apache). Defaults to 'true'.

*Note:* If `manage_apache` is set to true, `manage_vhost` will be ignored and the virtual host configuration will be installed even if it's set to false.

##### `url`

Configures the virtual host to install if `manage_apache` or `manage_vhost` are set to true. At this time there is no support for Apache server aliases. Defaults to `owncloud.${::domain}`

## Reference

### Classes

#### Public Classes

* `owncloud`: Guides the installation of ownCloud (including database creation and user data directory if specified).

#### Private Classes

* `ownCloud::config`: Configures ownCloud using an autoconfig.php (installs an Apache vhost and creates a database by default).
* `ownCloud::install`: Installs ownCloud (and ownCloud repository by default).
* `ownCloud::params`: Manages ownCloud operating system specific parameters.

## Limitations

* This module does not install a database server. An example has been provided on how to do this using [PuppetLabs MySQL module](https://github.com/puppetlabs/puppetlabs-mysql).

* This module has been tested on the following Operating Systems:

    * Ubuntu 12.04 Precise
    * Ubuntu 14.04 Trusty

## Development

In the pipeline:

* Add support for additional operating systems.
* Add support for PostgreSQL.
* Add support for SSL virtual hosts.

At this time only one instance of ownCloud can be configured per host. It would be easy enough to change to a define to make a multi-tenant ownCloud server, but wasn't a requirement when writing this and can only see this being implemented if someone wants to add this functionality via a pull request.

Pull requests are welcome, please see the [contributing guidelines](https://github.com/shoekstra/puppet-owncloud/blob/develop/CONTRIBUTING.md).
