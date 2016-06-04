require 'spec_helper'
require 'versionomy'

describe 'owncloud' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge(
            concat_basedir: '/var/lib/puppet/concat',
            root_home: '/root'
          )
        end

        case facts[:osfamily]
        when 'Debian'
          apache_user = 'www-data'
          apache_group = 'www-data'
          datadirectory = '/var/www/owncloud/data'
          documentroot = '/var/www/owncloud'
          package_name = 'owncloud-files'

          case facts[:operatingsystem]
          when 'Debian'
            if (Versionomy.parse(facts[:operatingsystemrelease]) > Versionomy.parse('8')) || (Versionomy.parse(facts[:operatingsystemrelease]) == Versionomy.parse('8'))
              apache_version = '2.4'
            else
              apache_version = '2.2'
            end
          when 'Ubuntu'
            apache_version = '2.4'
          end
        when 'RedHat'
          apache_user = 'apache'
          apache_group = 'apache'
          datadirectory = '/var/www/html/owncloud/data'
          documentroot = '/var/www/html/owncloud'
          package_name = 'owncloud-files'

          if (Versionomy.parse(facts[:operatingsystemrelease]) > Versionomy.parse('7')) || (Versionomy.parse(facts[:operatingsystemrelease]) == Versionomy.parse('7'))
            apache_version = '2.4'
          else
            apache_version = '2.2'
          end
        end

        context 'owncloud class without any parameters' do
          let(:params) { {} }

          # We expect the mysql::server class to be in use when using default params

          let :pre_condition do
            'class { "::mysql::server":
              override_options => {
                "mysqld" => { "bind-address" => "0.0.0.0" }
              },
              restart       => true,
              root_password => "sup3rt0ps3cr3t",
              }'
          end

          it 'should compile with all deps and cover all sub classes' do
            is_expected.to compile.with_all_deps

            is_expected.to contain_class('owncloud::params')
            is_expected.to contain_class('owncloud::php').that_comes_before('owncloud::install')
            is_expected.to contain_class('owncloud::install').that_comes_before('owncloud::apache')
            is_expected.to contain_class('owncloud::apache').that_comes_before('owncloud::config')
            is_expected.to contain_class('owncloud::config').that_comes_before('owncloud')
            is_expected.to contain_class('owncloud')

            is_expected.to contain_package("#{package_name}").with_ensure('present')
          end

          # owncloud::php

          it 'should install and configure php and php modules' do
            is_expected.to contain_class('php')

            if facts[:osfamily] == 'Debian'
              %w(curl gd ldap mysqlnd).each do |mod|
                is_expected.to contain_php__module(mod).that_requires('class[php]')
              end
            end

            if facts[:osfamily] == 'RedHat'
              %w(gd ldap mbstring mysql pdo process xml).each do |mod|
                is_expected.to contain_php__module(mod).that_requires('class[php]')
              end
            end
          end

          # owncloud::install

          it 'should create owncloud repo and install owncloud' do
            case facts[:osfamily]
            when 'Debian'
              is_expected.to contain_class('apt')

              is_expected.not_to contain_yumrepo('owncloud')

              case facts[:operatingsystem]
              when 'Debian'
                is_expected.to contain_apt__source('owncloud').with(
                  location: "http://download.owncloud.org/download/repositories/stable/Debian_#{facts[:operatingsystemmajrelease]}.0/",
                  key: {
                    'id' => 'BCECA90325B072AB1245F739AB7C32C35180350A',
                    'source' => "https://download.owncloud.org/download/repositories/stable/Debian_#{facts[:operatingsystemmajrelease]}.0/Release.key"
                  },
                  release: ' ',
                  repos: '/'
                ).that_comes_before("Package[#{package_name}]")
              when 'Ubuntu'
                is_expected.to contain_apt__source('owncloud').with(
                  location: "http://download.owncloud.org/download/repositories/stable/Ubuntu_#{facts[:operatingsystemrelease]}/",
                  key: {
                    'id' => 'BCECA90325B072AB1245F739AB7C32C35180350A',
                    'source' => "https://download.owncloud.org/download/repositories/stable/Ubuntu_#{facts[:operatingsystemrelease]}/Release.key"
                  },
                  release: ' ',
                  repos: '/'
                ).that_comes_before("Package[#{package_name}]")
              end
            when 'RedHat'
              is_expected.not_to contain_class('apt')
              is_expected.not_to contain_apt__source('owncloud')

              case facts[:operatingsystem]
              when 'CentOS'
                is_expected.to contain_yumrepo('owncloud').with(
                  descr: "ownCloud Server Version stable (CentOS_#{facts[:operatingsystemmajrelease]})",
                  baseurl: "http://download.owncloud.org/download/repositories/stable/CentOS_#{facts[:operatingsystemmajrelease]}/",
                  gpgcheck: 1,
                  gpgkey: "http://download.owncloud.org/download/repositories/stable/CentOS_#{facts[:operatingsystemmajrelease]}/repodata/repomd.xml.key",
                  enabled: 1
                ).that_comes_before("Package[#{package_name}]")
              end
            end

            is_expected.to contain_package("#{package_name}").with_ensure('present')
          end

          # owncloud::apache

          it 'should include class to manage webserver and create vhost' do
            is_expected.to contain_class('apache').with(
              default_vhost: false,
              mpm_module: 'prefork',
              purge_configs: false
            )

            is_expected.to contain_class('apache::mod::php')

            if facts[:osfamily] == 'Debian'
              %w(/etc/apache2/sites-enabled/000-default /etc/apache2/sites-enabled/000-default.conf).each do |file|
                is_expected.to contain_file(file).with_ensure('absent').that_requires('Class[apache]').that_notifies('Class[apache::service]')
              end
            end

            # check apache vhost is generated properly

            vhost_params = {
              'servername'    => 'owncloud.example.com',
              'port'          => '80',
              'docroot'       => "#{documentroot}",
              'docroot_owner' => 'root',
              'docroot_group' => 'root',
              'directories'   => {
                'path'           => "#{documentroot}",
                'options'        => ['Indexes', 'FollowSymLinks', 'MultiViews'],
                'allow_override' => 'All',
                'custom_fragment'=> 'Dav Off',
              }
            }
            if apache_version == '2.2'
              vhost_params['directories'] = vhost_params['directories'].merge({
                'order'    => 'allow,deny',
                'allow'    => 'from All',
                'satisfy'  => 'Any',
              })
            else
              vhost_params['directories'] = vhost_params['directories'].merge({
                'require'  => 'all granted',
              })
            end

            is_expected.to contain_apache__vhost('owncloud-http').with(vhost_params)
            is_expected.not_to contain_apache__vhost('owncloud-https')


=begin
            [
              /<VirtualHost \*:80>/,
              /ServerName owncloud./
            ].each do |line|
              is_expected.to contain_file('/var/lib/puppet/concat/25-owncloud-http.conf/fragments/0_owncloud-http-apache-header').with_content(line)
            end

            is_expected.to contain_File('/var/lib/puppet/concat/25-owncloud-http.conf/fragments/10_owncloud-http-docroot').with_content(/DocumentRoot "#{documentroot}"/)

            vhost_dir_config = [
              /<Directory "#{documentroot}">/,
              /Options Indexes FollowSymLinks MultiViews/,
              /AllowOverride All/,
              /Dav Off/,
              /<\/Directory>/
            ]

            if apache_version == '2.2'
              vhost_dir_config.concat([
                /Order allow,deny/,
                /Allow from All/,
                /Satisfy Any/
              ])
            else
              vhost_dir_config.concat([
                /Require all granted/
              ])
            end

            vhost_dir_config.each do |line|
              is_expected.to contain_File('/var/lib/puppet/concat/25-owncloud-http.conf/fragments/60_owncloud-http-directories').with_content(line)
=end
          end

          # owncloud::config

          it 'should create $datadirectory if it doesn\'t exist, create database, populate autoconfig.php.erb with default values, remove skeleton dirs' do
            is_expected.to contain_exec("mkdir -p #{datadirectory}").with(
              path: ['/bin', '/usr/bin'],
              unless: "test -d #{datadirectory}"
            ).that_comes_before("File[#{datadirectory}]")

            is_expected.to contain_file(datadirectory).with(
              ensure: 'directory',
              owner: apache_user,
              group: apache_group,
              mode: '0770'
            )

            is_expected.to contain_mysql__db('owncloud').with(
              user: 'owncloud',
              password: 'owncloud',
              host: 'localhost',
              grant: ['all']
            )

            default_autoconfig = <<-EOF.gsub(/^ {14}/, '')
              <?php
              $AUTOCONFIG = array(
                "dbtype"        => "mysql",
                "dbname"        => "owncloud",
                "dbuser"        => "owncloud",
                "dbpass"        => "owncloud",
                "dbhost"        => "localhost",
                "dbtableprefix" => "",
                "directory"     => "#{datadirectory}",
              );
            EOF

            is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with(
              ensure: 'present',
              owner: apache_user,
              group: apache_group
            ).with_content(default_autoconfig)

            %w(core/skeleton/documents core/skeleton/music core/skeleton/photos).each do |skeleton_dir|
              is_expected.to contain_file("#{documentroot}/#{skeleton_dir}").with(
                ensure: 'directory',
                recurse: true,
                purge: true
              )
            end
          end
        end

        context 'owncloud class with non default parameters' do
          describe 'when all manage_ parameters set to false' do
            let(:params) { { manage_apache: false, manage_db: false, manage_php: false, manage_repo: false, manage_skeleton: false, manage_vhost: false } }

            it 'should not manage any extras, just install and configure owncloud' do
              is_expected.not_to contain_class('php')

              %w(curl gd ldap mysqlnd).each do |mod|
                is_expected.not_to contain_php__module(mod).that_requires('class[php]')
              end

              if facts[:operatingsystem] == 'CentOS'
                %w(mbstring pecl-zip pdo process xml).each do |mod|
                  is_expected.not_to contain_php__module(mod)
                end
              end

              is_expected.not_to contain_class('apache::mod::php')
              is_expected.not_to contain_apache__vhost('owncloud-http')

              # should be an exported resource thus not in our catalogue.
              is_expected.not_to contain_mysql__db('owncloud')

              case facts[:osfamily]
              when 'Debian'
                is_expected.not_to contain_apt__source('owncloud')
              when 'RedHat'
                is_expected.not_to contain_class('yum::repo::epel')
                is_expected.not_to contain_class('yum::repo::remi_php70')
                is_expected.not_to contain_yumrepo('owncloud')
              end

              ['core/skeleton/documents', 'core/skeleton/music', 'core/skeleton/photos'].each do |skeleton_dir|
                is_expected.not_to contain_file("#{documentroot}/#{skeleton_dir}")
              end
            end
          end

          describe 'when db_host is not set to "localhost"' do
            let(:params) { { db_host: 'test' } }

            it 'should not have a database resource in the catalogue (exported resource) and should populate autoconfig.php.erb correctly' do
              is_expected.not_to contain_mysql__db('owncloud')
              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "dbhost"(\ *)=> "test",$/)
            end
          end

          describe 'when db_type is not supported' do
            let(:params) { { db_type: 'test' } }

            it 'should raise an error' do
              expect raise_error
            end
          end

          describe 'when remaining db_parameters are set' do
            let(:params) { { db_name: 'test', db_table_prefix: 'test', db_user: 'test', db_pass: 'test' } }

            it 'should populate database parameters and autoconfig.php.erb correctly' do
              is_expected.to contain_mysql__db('test').with(
                user: 'test',
                password: 'test'
              )

              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "dbname"(\ *)=> "test",$/)
              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "dbuser"(\ *)=> "test",$/)
              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "dbpass"(\ *)=> "test",$/)
              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "dbtableprefix"(\ *)=> "test",$/)
            end
          end

          describe 'when admin login credentials are set' do
           let(:params) { { admin_user: 'test', admin_pass: 'test'} }

            it 'should populate autoconfig.php.erb correctly' do
              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "adminlogin"(\ *)=> "test",$/)
              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "adminpass"(\ *)=> "test",$/)
            end
          end

          describe 'when datadirectory is set to "/test"' do
            let(:params) { { datadirectory: '/test' } }

            it 'should create /test dir and populate autoconfig.php.erb correctly' do
              is_expected.to contain_exec('mkdir -p /test').with(
                path: ['/bin', '/usr/bin'],
                unless: 'test -d /test'
              ).that_comes_before('File[/test]')

              is_expected.to contain_file('/test').with(
                ensure: 'directory',
                owner: apache_user,
                group: apache_group,
                mode: '0770'
              )

              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "directory"(\ *)=> "\/test",$/)
            end
          end

          describe 'when php_modules are defined' do
            let(:params) { { php_modules: ['mod1','mod2']} }

            it 'should install extra php modules' do
              %w(mod1 mod2).each do |mod|
                is_expected.to contain_php__module(mod).that_requires('class[php]')
              end
            end
          end

          describe 'when ssl is enabled with ssl_cert and ssl_key parameters' do
            let :params do
              {
                ssl: true,
                ssl_cert: '/srv/www/owncloud/certs/cert.crt',
                ssl_key: '/srv/www/owncloud/certs/key.crt'
              }
            end

            it 'should have https vhost and http redirect vhost' do
              is_expected.to contain_apache__vhost('owncloud-http').with(port: 80)
              is_expected.to contain_apache__vhost('owncloud-https').with(port: 443)
            end
          end

          describe 'when trusted_domains are set' do
           let(:params) { { trusted_domains: ['test']} }

            it 'should populate autoconfig.php.erb correctly' do
              is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/^  "trusted_domains"(\ *)=> \["test"\],$/)
            end
          end

          describe 'when all vhost related parameters are set' do
            let :params do
              {
                http_port: 8080,
                https_port: 8443,
                ssl: true,
                ssl_ca: '/srv/www/owncloud/certs/ca.crt',
                ssl_cert: '/srv/www/owncloud/certs/cert.crt',
                ssl_chain: '/srv/www/owncloud/certs/chain.crt',
                ssl_key: '/srv/www/owncloud/certs/key.crt',
                url: 'owncloud.company.tld'
              }
            end

            it 'should have https vhost and http redirect vhost, listen on non standard ports, servername not set to host fqdn' do
              is_expected.to contain_apache__vhost('owncloud-http').with(port: 8080)
              is_expected.to contain_apache__vhost('owncloud-https').with(
                port: 8443,
                servername: 'owncloud.company.tld',
                ssl_ca: '/srv/www/owncloud/certs/ca.crt',
                ssl_cert: '/srv/www/owncloud/certs/cert.crt',
                ssl_chain: '/srv/www/owncloud/certs/chain.crt',
                ssl_key: '/srv/www/owncloud/certs/key.crt',
                ssl: true
              )
            end
          end
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'owncloud class without any parameters on Solaris/Nexenta' do
      package_name = 'owncloud-files'
      let(:facts) do
        {
          osfamily: 'Solaris',
          operatingsystem: 'Nexenta'
        }
      end

      it { expect { is_expected.to contain_package("#{package_name}") }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
