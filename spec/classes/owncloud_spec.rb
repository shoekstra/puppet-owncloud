require 'spec_helper'

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
        when 'RedHat'
          apache_user = 'apache'
          apache_group = 'apache'
          datadirectory = '/var/www/html/owncloud/data'
          documentroot = '/var/www/html/owncloud'
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

          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('owncloud::params') }
          it { is_expected.to contain_class('owncloud::install').that_comes_before('owncloud::apache') }
          it { is_expected.to contain_class('owncloud::apache').that_comes_before('owncloud::config') }
          it { is_expected.to contain_class('owncloud::config').that_comes_before('owncloud') }
          it { is_expected.to contain_class('owncloud') }

          it { is_expected.to contain_package('owncloud').with_ensure('present') }

          # owncloud::install

          case facts[:osfamily]
          when 'Debian'
            it { is_expected.to contain_class('apt') }

            it { is_expected.not_to contain_class('epel') }
            it { is_expected.not_to contain_yumrepo('isv:ownCloud:community') }

            case facts[:operatingsystem]
            when 'Debian'
              it do
                is_expected.to contain_apt__source('owncloud').with(
                  location: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Debian_#{facts[:operatingsystemmajrelease]}.0/",
                  include_src: false,
                  key: 'BA684223',
                  key_source: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Debian_#{facts[:operatingsystemmajrelease]}.0/Release.key",
                  release: '',
                  repos: '/'
                ).that_comes_before('Package[owncloud]')
              end
            when 'Ubuntu'
              it do
                is_expected.to contain_apt__source('owncloud').with(
                  location: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_#{facts[:operatingsystemrelease]}/",
                  include_src: false,
                  key: 'BA684223',
                  key_source: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_#{facts[:operatingsystemrelease]}/Release.key",
                  release: '',
                  repos: '/'
                ).that_comes_before('Package[owncloud]')
              end
            end
          when 'RedHat'
            it { is_expected.not_to contain_class('apt') }
            it { is_expected.not_to contain_apt__source('owncloud') }

            case facts[:operatingsystem]
            when 'CentOS'
              it { is_expected.to contain_class('epel') }

              it do
                is_expected.to contain_yumrepo('isv:ownCloud:community').with(
                  name: 'isv_ownCloud_community',
                  # descr: "Latest stable community release of ownCloud (CentOS_CentOS-#{facts[:operatingsystemmajrelease]})",
                  descr: "Latest stable community release of ownCloud (CentOS_CentOS-#{facts[:operatingsystemmajrelease]})",
                  baseurl: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/CentOS_CentOS-#{facts[:operatingsystemmajrelease]}/",
                  gpgcheck: 1,
                  gpgkey: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/CentOS_CentOS-#{facts[:operatingsystemmajrelease]}/repodata/repomd.xml.key",
                  enabled: 1
                ).that_comes_before('Package[owncloud]')
              end
            when 'Fedora'
              it { is_expected.not_to contain_class('epel') }

              it do
                is_expected.to contain_yumrepo('isv:ownCloud:community').with(
                  name: 'isv_ownCloud_community',
                  # descr: "Latest stable community release of ownCloud (Fedora_#{facts[:operatingsystemmajrelease]})",
                  descr: "Latest stable community release of ownCloud (Fedora_#{facts[:operatingsystemmajrelease]})",
                  baseurl: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Fedora_#{facts[:operatingsystemmajrelease]}/",
                  gpgcheck: 1,
                  gpgkey: "http://download.opensuse.org/repositories/isv:/ownCloud:/community/Fedora_#{facts[:operatingsystemmajrelease]}/repodata/repomd.xml.key",
                  enabled: 1
                ).that_comes_before('Package[owncloud]')
              end
            end
          end

          it { is_expected.to contain_package('owncloud').with_ensure('present') }

          # owncloud::apache

          it do
            is_expected.to contain_class('apache').with(
              default_vhost: false,
              mpm_module: 'prefork',
              purge_configs: false
            )
          end

          # We only test for the php module, ssl and rewrite are auto included by Apache module.

          it { is_expected.to contain_class('apache::mod::php') }

          it do
            is_expected.to contain_apache__vhost('owncloud-http').with(
              servername: 'owncloud.example.com',
              port: '80'
            )
          end

          it { is_expected.not_to contain_apache__vhost('owncloud-https').with(servername: 'owncloud.example.com') }

          # owncloud::config

          it do
            is_expected.to contain_exec("mkdir -p #{datadirectory}").with(
              path: ['/bin', '/usr/bin'],
              unless: "test -d #{datadirectory}"
            ).that_comes_before("File[#{datadirectory}]")
          end

          it do
            is_expected.to contain_file(datadirectory).with(
              ensure: 'directory',
              owner: apache_user,
              group: apache_group,
              mode: '0770'
            )
          end

          it do
            is_expected.to contain_mysql__db('owncloud').with(
              user: 'owncloud',
              password: 'owncloud',
              host: 'localhost',
              grant: ['all']
            )
          end

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
            is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with(
              ensure: 'present',
              owner: apache_user,
              group: apache_group
            ).with_content(default_autoconfig)
          end

          %w(core/skeleton/documents core/skeleton/music core/skeleton/photos).each do |skeleton_dir|
            it do
              is_expected.to contain_file("#{documentroot}/#{skeleton_dir}").with(
                ensure: 'directory',
                recurse: true,
                purge: true
              )
            end
          end
        end

        context 'owncloud class with non default parameters' do
          describe 'when http_port is set to "8080"' do
            let(:params) { { http_port: 8080 } }

            it do
              is_expected.to contain_apache__vhost('owncloud-http').with(
                port: 8080
              )
            end
          end

          describe 'when manage_apache is set to false' do
            let(:params) { { manage_apache: false } }

            # Can't work out how to test that the apache class is not called by the owncloud module - it needs
            # to be in the catalogue using a pre_condition in order for the vhost to install (we still manage
            # the vhost if manage_apache is set to false).
            #
            # it { is_expected.not_to contain_class('apache') }

            let :pre_condition do
              'class { "::apache":
                mpm_module    => "prefork",
                purge_configs => false,
                default_vhost => true,
              }'
            end

            it { is_expected.not_to contain_class('apache::mod::php') }
          end

          describe 'when db_host is set to "mysqlserver"' do
            let(:params) { { db_host: 'mysqlserver' } }

            it { is_expected.not_to contain_mysql__db('owncloud') }
            it { is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/\"dbhost\"(\ *)=> \"mysqlserver\",/) }
          end

          describe 'when db_name is set to "owncloud_db"' do
            let(:params) { { db_name: 'owncloud_db' } }

            it { is_expected.to contain_mysql__db('owncloud_db') }
            it { is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/\"dbname\"(\ *)=> \"owncloud_db\",/) }
          end

          describe 'when db_user is set to "owncloud_user"' do
            let(:params) { { db_user: 'owncloud_user' } }

            it { is_expected.to contain_mysql__db('owncloud').with(user: 'owncloud_user') }
            it { is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/\"dbuser\"(\ *)=> \"owncloud_user\",/) }
          end

          describe 'when db_pass is set to "owncloud_pass"' do
            let(:params) { { db_pass: 'owncloud_pass' } }

            it { is_expected.to contain_mysql__db('owncloud').with(password: 'owncloud_pass') }
            it { is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(/\"dbpass\"(\ *)=> \"owncloud_pass\",/) }
          end

          describe 'when db_type is set to "postgres"' do
            let(:params) { { db_type: 'postgres' } }

            it { expect raise_error }
          end

          describe 'when db_datadirectory is set to "/srv/owncloud/data"' do
            let(:params) { { datadirectory: '/srv/owncloud/data' } }

            it do
              is_expected.to contain_exec('mkdir -p /srv/owncloud/data').with(
                path: ['/bin', '/usr/bin'],
                unless: 'test -d /srv/owncloud/data'
              ).that_comes_before('File[/srv/owncloud/data]')
            end

            it do
              is_expected.to contain_file('/srv/owncloud/data').with(
                ensure: 'directory',
                owner: apache_user,
                group: apache_group,
                mode: '0770'
              )
            end

            it { is_expected.to contain_file("#{documentroot}/config/autoconfig.php").with_content(%r{\"directory\"(\ *)=> \"/srv/owncloud/data\",}) }
          end

          describe 'when manage_db is set to false' do
            let(:params) { { manage_db: false } }

            # is_expected.to be an exported resource thus not in our catalogue.
            it { is_expected.not_to contain_mysql__db('owncloud') }
          end

          describe 'when manage_repo is set to false' do
            let(:params) { { manage_repo: false } }

            case facts[:osfamily]
            when 'Debian'
              it { is_expected.not_to contain_apt__source('owncloud') }
            when 'RedHat'
              it { is_expected.not_to contain_class('epel') }
              it { is_expected.not_to contain_yumrepo('isv:ownCloud:community') }
            end
          end

          describe 'when manage_skeleton is set to false' do
            let(:params) { { manage_skeleton: false } }

            ['core/skeleton/documents', 'core/skeleton/music', 'core/skeleton/photos'].each do |skeleton_dir|
              it { is_expected.not_to contain_file("#{documentroot}/#{skeleton_dir}") }
            end
          end

          describe 'when manage_vhost is set to false' do
            let(:params) { { manage_vhost: false } }

            it { is_expected.to contain_class('apache') }
            it { is_expected.to contain_class('apache::mod::php') }
            it { is_expected.not_to contain_apache__vhost('owncloud-http') }
          end

          describe 'when ssl is set to true (and has related cert params)' do
            let :params do
              {
                ssl: true,
                ssl_ca: '/srv/www/owncloud/certs/ca.crt',
                ssl_cert: '/srv/www/owncloud/certs/cert.crt',
                ssl_chain: '/srv/www/owncloud/certs/chain.crt',
                ssl_key: '/srv/www/owncloud/certs/key.crt'
              }
            end

            it { is_expected.to contain_apache__vhost('owncloud-http').with(port: 80) }

            it do
              is_expected.to contain_apache__vhost('owncloud-https').with(
                port: 443,
                ssl_ca: '/srv/www/owncloud/certs/ca.crt',
                ssl_cert: '/srv/www/owncloud/certs/cert.crt',
                ssl_chain: '/srv/www/owncloud/certs/chain.crt',
                ssl_key: '/srv/www/owncloud/certs/key.crt',
                ssl: true
              )
            end
          end

          describe 'when ssl is set to true (and https_port is set to 8443)' do
            let :params do
              {
                https_port: 8443,
                ssl: true,
                ssl_cert: '/srv/www/owncloud/certs/cert.crt',
                ssl_key: '/srv/www/owncloud/certs/key.crt'
              }
            end

            it { is_expected.to contain_apache__vhost('owncloud-https').with(port: 8443) }
          end

          describe 'when url is set to "owncloud.company.tld"' do
            let(:params) { { url: 'owncloud.company.tld' } }

            it { is_expected.to contain_apache__vhost('owncloud-http').with(servername: 'owncloud.company.tld') }
          end
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'owncloud class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          osfamily: 'Solaris',
          operatingsystem: 'Nexenta'
        }
      end

      it { expect { is_expected.to contain_package('owncloud') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
