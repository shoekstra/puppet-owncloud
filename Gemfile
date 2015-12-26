source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :development do
  gem 'guard-rake',                   :require => false
  gem 'puppet-blacksmith',            :require => false
end

group :unit_tests do
  gem 'metadata-json-lint',           :require => false
  gem 'puppetlabs_spec_helper',       :require => false
  gem 'rspec-core', '3.1.7',          :require => false
  gem 'rspec-puppet-facts',           :require => false
  gem 'simplecov',                    :require => false
  gem 'versionomy',                   :require => false
end

group :system_tests do
  gem 'beaker-rspec',                 :require => false
  gem 'beaker-puppet_install_helper', :require => false
  gem 'serverspec',                   :require => false
  gem 'vagrant-wrapper',              :require => false
end

gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 4.0.0'

# vim:ft=ruby
