require 'spec_helper'

describe 'owncloud' do
  context 'on supported operating systems' do
    ['Ubuntu'].each do |os|
      describe "such as #{os}" do
        case os
        when 'Ubuntu'
          let :facts do
            {
              concat_basedir: '/var/lib/puppet/concat',
              domain: 'example.com',
              fqdn: 'server.example.com',
              ipaddress: '192.168.10.20',
              lsbdistid: 'Ubuntu',
              lsbdistcodename: 'precise',
              operatingsystem: 'Ubuntu',
              operatingsystemrelease: '12.04',
              osfamily: 'Debian'
            }
          end

          apache_user = 'www-data'
          apache_group = 'www-data'
          basedirectory = '/var/www/owncloud'
          datadirectory = "#{basedirectory}/data"
        end

        context 'with module defaults' do
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

          it { should compile.with_all_deps }

          it { should contain_class('owncloud::params') }
          it { should contain_class('owncloud::install').that_comes_before('owncloud::apache') }
          it { should contain_class('owncloud::apache').that_comes_before('owncloud::config') }
          it { should contain_class('owncloud::config').that_comes_before('owncloud') }
          it { should contain_class('owncloud') }

          # owncloud::install

          case os
          when 'Ubuntu'
            it do
              should contain_apt__source('owncloud').with(
                location: 'http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_12.04/',
                key_source: 'http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_12.04/Release.key'
              ).that_comes_before('Package[owncloud]')
            end
          end

          it { should contain_package('owncloud').with_ensure('present') }

          # owncloud::apache

          it do
            should contain_class('apache').with(
              default_vhost: false,
              mpm_module: 'prefork',
              purge_configs: false
            )
          end

          %w(php rewrite ssl).each do |apache_mod|
            it { should contain_class("apache::mod::#{apache_mod}") }
          end

          it { should contain_apache__vhost('owncloud-http').with(servername: 'owncloud.example.com') }

          # owncloud::config

          it do
            should contain_exec("mkdir -p #{datadirectory}").with(
              path: ['/bin', '/usr/bin'],
              unless: "test -d #{datadirectory}"
            ).that_comes_before("File[#{datadirectory}]")
          end

          it do
            should contain_file(datadirectory).with(
              ensure: 'directory',
              owner: apache_user,
              group: apache_group,
              mode: '0770'
            )
          end

          it { should contain_mysql__db('owncloud') }

          default_autoconfig = <<-EOF.gsub(/^ {12}/, '')
            <?php
            $AUTOCONFIG = array(
              \"dbtype\"        => \"mysql\",
              \"dbname\"        => \"owncloud\",
              \"dbuser\"        => \"owncloud\",
              \"dbpass\"        => \"owncloud\",
              \"dbhost\"        => \"localhost\",
              \"dbtableprefix\" => \"\",
              \"directory\"     => \"#{datadirectory}\",
            );
          EOF

          it do
            should contain_file("#{basedirectory}/config/autoconfig.php").with(
              ensure: 'present',
              owner: apache_user,
              group: apache_group
            ).with_content(default_autoconfig)
          end

          %w(core/skeleton/documents core/skeleton/music core/skeleton/photos).each do |skeleton_dir|
            it do
              should contain_file("#{basedirectory}/#{skeleton_dir}").with(
                ensure: 'directory',
                recurse: true,
                purge: true
              )
            end
          end
        end

        context 'using non default parameters' do
          describe 'when manage_apache is set to false' do
            let(:params) { { manage_apache: false } }

            # Can't work out how to test that the apache class is not called by the owncloud module - it needs
            # to be in the catalogue using a pre_condition in order for the vhost to install (we still manage
            # the vhost if manage_apache is set to false).
            #
            # it { should_not contain_class('apache') }

            let :pre_condition do
              'class { "::apache":
                mpm_module    => "prefork",
                purge_configs => false,
                default_vhost => true,
              }'
            end

            %w(php rewrite ssl).each do |apache_mod|
              it { should_not contain_class("apache::mod::#{apache_mod}") }
            end
          end

          describe 'when db_host is set to "mysqlserver"' do
            let(:params) { { db_host: 'mysqlserver' } }

            it { should_not contain_mysql__db('owncloud') }
            it { should contain_file("#{basedirectory}/config/autoconfig.php").with_content(/\"dbhost\"(\ *)=> \"mysqlserver\",/) }
          end

          describe 'when db_name is set to "owncloud_db"' do
            let(:params) { { db_name: 'owncloud_db' } }

            it { should contain_mysql__db('owncloud_db') }
            it { should contain_file("#{basedirectory}/config/autoconfig.php").with_content(/\"dbname\"(\ *)=> \"owncloud_db\",/) }
          end

          describe 'when db_user is set to "owncloud_user"' do
            let(:params) { { db_user: 'owncloud_user' } }

            it { should contain_mysql__db('owncloud').with(user: 'owncloud_user') }
            it { should contain_file("#{basedirectory}/config/autoconfig.php").with_content(/\"dbuser\"(\ *)=> \"owncloud_user\",/) }
          end

          describe 'when db_pass is set to "owncloud_pass"' do
            let(:params) { { db_pass: 'owncloud_pass' } }

            it { should contain_mysql__db('owncloud').with(password: 'owncloud_pass') }
            it { should contain_file("#{basedirectory}/config/autoconfig.php").with_content(/\"dbpass\"(\ *)=> \"owncloud_pass\",/) }
          end

          describe 'when db_type is set to "postgres"' do
            let(:params) { { db_type: 'postgres' } }

            it { expect raise_error }
          end

          describe 'when db_datadirectory is set to "/srv/owncloud/data"' do
            let(:params) { { datadirectory: '/srv/owncloud/data' } }

            it do
              should contain_exec('mkdir -p /srv/owncloud/data').with(
                path: ['/bin', '/usr/bin'],
                unless: 'test -d /srv/owncloud/data'
              ).that_comes_before('File[/srv/owncloud/data]')
            end

            it do
              should contain_file('/srv/owncloud/data').with(
                ensure: 'directory',
                owner: apache_user,
                group: apache_group,
                mode: '0770'
              )
            end

            it { should contain_file("#{basedirectory}/config/autoconfig.php").with_content(%r{\"directory\"(\ *)=> \"/srv/owncloud/data\",}) }
          end

          describe 'when manage_db is set to false' do
            let(:params) { { manage_db: false } }

            # Should be an exported resource thus not in our catalogue.
            it { should_not contain_mysql__db('owncloud') }
          end

          describe 'when manage_repo is set to false' do
            let(:params) { { manage_repo: false } }

            case os
            when 'Ubuntu'
              it { should_not contain_apt__source('owncloud') }
            end
          end

          describe 'when manage_skeleton is set to false' do
            let(:params) { { manage_skeleton: false } }

            ['core/skeleton/documents', 'core/skeleton/music', 'core/skeleton/photos'].each do |skeleton_dir|
              it { should_not contain_file("#{basedirectory}/#{skeleton_dir}") }
            end
          end

          describe 'when manage_vhost is set to false' do
            let(:params) { { manage_vhost: false } }

            it { should contain_class('apache') }
            %w(php rewrite ssl).each do |apache_mod|
              it { should contain_class("apache::mod::#{apache_mod}") }
            end
            it { should_not contain_apache__vhost('owncloud-http') }
          end

          describe 'when url is set to "owncloud.company.tld"' do
            let(:params) { { url: 'owncloud.company.tld' } }

            it { should contain_apache__vhost('owncloud-http').with(servername: 'owncloud.company.tld') }
          end
        end
      end
    end
  end

  context 'on unsupported operating systems' do
    let :facts do
      {
        osfamily: 'Solaris',
        operatingsystem: 'Nexenta'
      }
    end

    it { expect raise_error(Puppet::Error, /Nexenta not supported/) }
  end
end
