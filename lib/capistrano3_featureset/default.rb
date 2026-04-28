# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Include rsync with remote cache
require 'capistrano/rsync'
install_plugin Capistrano::SCM::Rsync

require 'capistrano/rvm'
require 'capistrano/rails'
begin
  require 'whenever/capistrano'
rescue StandardError, LoadError
  nil
end

load File.expand_path('tasks/featureset.rake', __dir__)
