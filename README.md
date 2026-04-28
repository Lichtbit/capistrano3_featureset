# Capistrano3 - Feature set

## Installation

Add this line to your application's Gemfile:

```ruby
  gem 'capistrano3_featureset'
```

And then execute:

    $ bundle install

Add this to your deployment files:

```ruby
# Capfile

require 'capistrano3_featureset/default'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
```

```ruby
# config/deploy.rb

# config valid for current version and patch releases of Capistrano
lock '~> 3.11.2'

set :application, 'application-name'
set :repo_url, 'git@github.com:your-repo.git'
set :deploy_to, '/srv/application-name'

set :rvm_ruby_version, '3.1.1'

# set :enable_delayed_job, false # default is false
# set :enable_solid_queue, false # default is false
# set :enable_whenever, false # default is false
# set :enable_unicorn, false # default is false
# set :enable_puma, false # default is false
# set :systemd_usage, true # default is true
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Integration of Capistrano 3.7.1+ rsync plugin

see https://github.com/infovore/capistrano-rsync-plugin
