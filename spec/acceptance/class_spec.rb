require 'spec_helper_acceptance'

describe 'owncloud class' do

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { '::mysql::server':
        override_options => {
          'mysqld' => { 'bind-address' => '0.0.0.0' }
        },
        restart       => true,
        root_password => 'password',
      }

      class { '::owncloud': }

      Class['::mysql::server'] -> Class['::owncloud']
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe package('owncloud-files') do
      it { is_expected.to be_installed }
    end

    describe command('php -m') do
      %w(ctype dom GD iconv JSON libxml mb posix SimpleXML XMLWriter zip zlib).each do |mod|
        its(:stdout) { should match /#{mod}/i }
      end
    end

    describe command('curl -Is http://localhost | head -n 1') do
      its(:stdout) { should match /200 OK/ }
    end

    describe command('curl -s http://localhost') do
      its(:stdout) { should match /\<title\>.*ownCloud.*\<\/title\>/m } # Test title is correct
      its(:stdout) { should match /placeholder="Username"/ } # Test username field box exists
      its(:stdout) { should match /placeholder="Password"/ } # Test password field box exists
    end
  end
end
