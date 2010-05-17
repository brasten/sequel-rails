source 'http://rubygems.org'

sequel = 'http://github.com/jeremyevans'

gem 'rake',                 '~> 0.8.7'
gem 'jeweler',              '~> 1.4'
gem 'yard',                 '~> 0.5'

git 'git://github.com/rails/rails.git' do

  gem 'activesupport',      '~> 3.0.0.beta3', :require => 'active_support'
  gem 'actionpack',         '~> 3.0.0.beta3', :require => 'action_pack'
  gem 'railties',           '~> 3.0.0.beta3', :require => 'rails'

end

gem 'sequel',              '~> 3.10.0'#, :git => "#{sequel}/sequel.git"

group :test do
  gem 'rspec'
  gem 'autotest'
  gem 'rcov'
end
