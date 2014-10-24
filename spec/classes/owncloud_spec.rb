require 'spec_helper'

describe 'owncloud', :type => :class do
  let :default_facts do
    {
      :concat_basedir => '/var/lib/puppet/concat',
    }
  end

  # Let's just set Ubuntu facts as defaults.
  let :facts do default_facts.merge(
    {
      :lsbdistid              => 'Ubuntu',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '12.04',
      :osfamily               => 'Debian',
    })
  end

  # We'll turn off any external dependencies and test each one by one.. 
  let :default_params do
    {
      :manage_apache   => false,
      :manage_db       => false,
      :manage_repo     => false,
      :manage_skeleton => false,
      :manage_vhost    => false,
    }
  end

  context 'supported operating systems' do
    describe "Ubuntu" do
      # Set some Ubuntu related facts for later..
      let :ubuntu_facts do default_facts.merge(
        {
          :lsbdistid              => 'Ubuntu',
          :lsbdistcodename        => 'precise', 
          :operatingsystem        => 'Ubuntu',
          :operatingsystemrelease => '12.04',
          :osfamily               => 'Debian',
        })
      end

      let :ubuntu_params do default_params.merge(
        {
          :datadirectory => '/var/www/owncloud/data',
        })
      end

      let :facts do ubuntu_facts.merge({}) end
      let :params do ubuntu_params.merge({}) end

      it { should compile.with_all_deps }

      it { should contain_class('owncloud::params') }
      it { should contain_class('owncloud::install').that_comes_before('owncloud::config') }
      it { should contain_class('owncloud::config').that_comes_before('owncloud') }
      it { should contain_class('owncloud') }

      it { should contain_package('owncloud').with_ensure('present') }

      it { should contain_file('/var/www/owncloud/config/autoconfig.php').with(
        'ensure' => 'present',
        'owner'  => 'www-data',
        'group'  => 'www-data',
      ) }

      ['12.04', '14.04'].each do |operatingsystemrelease|
        context "when $manage_repo is true, should install correct repo for #{operatingsystemrelease}" do
          let :facts do ubuntu_facts.merge({ :operatingsystemrelease => operatingsystemrelease }) end
          let :params do ubuntu_params.merge({ :manage_repo => true }) end

          it { should contain_apt__source('owncloud').with(
            'location'   => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_#{operatingsystemrelease}/",
            'key_source' => "http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_#{operatingsystemrelease}/Release.key",
          ).that_comes_before('Package[owncloud]')}
        end
      end

      context "when $manage_skeleton is true," do
        let :params do ubuntu_params.merge({ :manage_skeleton => true }) end

        ['core/skeleton/documents', 'core/skeleton/music', 'core/skeleton/photos'].each do |skeleton_dir|
          describe "it should manage the #{skeleton_dir} directory and purge any unmanaged files" do
            it { should contain_file("/var/www/owncloud/#{skeleton_dir}").with(
              {
              'ensure'  => 'directory',
              'recurse' => true,
              'purge'   => true,
              }
            )}
          end
        end
      end

    end

    [
      {
        :attr  => 'db_host',
        :title => "should set db_host",
        :value => 'localhost',
        :match => [/^  "dbhost"( *)=> "localhost",$/]
      },
      {
        :attr  => 'db_name',
        :title => "should set db_name",
        :value => 'owncloud',
        :match => [/^  "dbname"( *)=> "owncloud",$/]
      },
      {
        :attr  => 'db_pass',
        :title => "should set db_pass",
        :value => 'owncloud',
        :match => [/^  "dbpass"( *)=> "owncloud",$/]

      },
      {
        :attr  => 'db_user',
        :title => "should set db_user",
        :value => 'owncloud',
        :match => [/^  "dbuser"( *)=> "owncloud",$/]
      },
      {
        :attr  => 'db_type',
        :title => "should set db_type",
        :value => 'mysql',
        :match => [/^  "dbtype"( *)=> "mysql",$/]
      },
      {
        :attr  => 'datadirectory',
        :title => "should set datadirectory",
        :value => '/var/www/owncloud/data',
        :match => [/^  "directory"( *)=> "\/var\/www\/owncloud\/data",$/]
      }
    ].each do |param|
      describe "when \$#{param[:attr]} is #{param[:value]}" do
        let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

        it "#{param[:title]} to \'#{param[:value]}\'" do
          should contain_file('/var/www/owncloud/config/autoconfig.php').with_content(param[:match])
        end
      end
    end

    context 'when $datadirectory is /var/www/owncloud/data' do
      it { should contain_exec('mkdir -p /var/www/owncloud/data').with(
        {
          'path'   => ['/bin', '/usr/bin'],
          'unless' => 'test -d /var/www/owncloud/data'
        }
      )}

      it { should contain_file('/var/www/owncloud/data').with(
        {
          'ensure' => 'directory',
          'owner'  => 'www-data',
          'group'  => 'www-data',
          'mode'   => '0770'
        }
      )}
    end

    context "when $manage_apache is true, install apache and manage vhost," do
      let :params do default_params.merge( { :manage_apache => true }) end

      it { should contain_class('apache').that_comes_before('Package[owncloud]') }

      [true, false].each do |bool|
        describe "even manage vhost when \$manage_vhost is #{bool} (because we manage apache)" do
          let :params do default_params.merge( { :manage_apache => true, :manage_vhost => bool }) end

          ['php', 'rewrite', 'ssl'].each do |apache_mod|
            describe "it should include the #{apache_mod} apache module" do
              it { should contain_class("apache::mod::#{apache_mod}").that_comes_before('Class[owncloud::config]') }
            end
          end

          it { should contain_apache__vhost('owncloud-http') }
        end
      end
    end

    context "when $manage_apache is false and $manage_host is true, manage vhost (and include required modules)," do
      let :params do default_params.merge( { :manage_apache => false, :manage_vhost => true }) end

      let :pre_condition do
        'class { "::apache":
          mpm_module    => "prefork",
          purge_configs => false,
          default_vhost => true,
        }'
      end

      ['php', 'rewrite', 'ssl'].each do |apache_mod|
        describe "it should include the #{apache_mod} apache module" do
          it { should contain_class("apache::mod::#{apache_mod}").that_comes_before('Class[owncloud::config]') }
        end
      end

      it { should contain_apache__vhost('owncloud-http') }
    end

    context "when $manage_db is true," do
      describe "it should create a database" do
        let :params do default_params.merge(
          {
            :db_host   => 'localhost',
            :db_name   => 'owncloud_db_name',
            :db_pass   => 'owncloud_db_pass',
            :db_user   => 'owncloud_db_user',
            :db_type   => 'mysql',
            :manage_db => true,
          })
        end

        it { should contain_mysql__db('owncloud_db_name') }
      end
    end

  end

  context 'unsupported operating system' do
    let(:facts) {{
      :osfamily        => 'Solaris',
      :operatingsystem => 'Nexenta',
    }}

    it { expect { should contain_package('owncloud') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
  end
end
