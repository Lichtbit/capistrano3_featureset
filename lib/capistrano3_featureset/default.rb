# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Include rsync with remote cache
require 'capistrano/rsync'
install_plugin Capistrano::SCM::Rsync

require 'capistrano/rails'
begin
  require 'whenever/capistrano'
rescue StandardError, LoadError
  nil
end


namespace :load do
  task :defaults do
    set :ruby_map_bins, %w{gem rake ruby bundle}
    set :rvm_type, :user

    rsync_excludes = %w[.git* spec rspec test Capfile config/deploy config/deploy.rb]
    set :rsync_options, "-azc --delete --delete-excluded --exclude #{rsync_excludes.join(' --exclude ')}"

    set :version_manager, 'mise'
    set :enable_delayed_job, false
    set :enable_solid_queue, false
    set :enable_whenever, false
    set :enable_unicorn, false
    set :enable_puma, false

    set :systemd_usage, true

    append :linked_dirs, 'public/uploads'
    append :linked_dirs, 'private'
    append :linked_dirs, 'log'
    set :more_linked_dirs, 'tmp/pids' => 'pids'
  end
end

load File.expand_path('tasks/version_manager.rake', __dir__)
load File.expand_path('tasks/featureset.rake', __dir__)
