require 'rubygems'
require 'rake'

begin

  require 'jeweler'

  Jeweler::Tasks.new do |gem|

    gem.name        = 'sequel-rails'
    gem.summary     = 'Use Sequel with Rails 3'
    gem.description = 'Integrate Sequel with Rails 3'
    gem.email       = 'brasten@gmail.com'
    gem.homepage    = 'http://github.com/brasten/sequel-rails'
    gem.authors     = [ 'Brasten Sager (brasten)' ]

    gem.add_dependency 'sequel',           '~> 3.13'

    gem.add_dependency 'activesupport',     '~> 3.0.0.rc'
    gem.add_dependency 'actionpack',        '~> 3.0.0.rc'
    gem.add_dependency 'railties',          '~> 3.0.0.rc'

    # gem.add_development_dependency 'yard',  '~> 0.5'

  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }

rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end
