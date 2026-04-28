namespace :featureset do
  desc 'generate static error 500 pages'
  task :generate_static_500_html do
    on roles(:web) do |host|
      next unless host.properties.error_500_url

      within release_path do
        execute :curl, '-sk', host.properties.error_500_url, '-o', 'public/500.html'
      end
    end
  end

  desc 'generate static error pages'
  task :generate_static_error_html do
    on roles(:web) do |host|
      next unless host.properties.static_error_urls
      next unless host.properties.static_error_urls.is_a?(Hash)

      within release_path do
        host.properties.static_error_urls.each do |name, url|
          execute :curl, '-sk', url, '-o', name
        end
      end
    end
  end

  desc 'load full schema to prevent old migration errors'
  task :db_load_schema do
    on roles(:db) do
      within release_path do
        with(
          rails_env: fetch(:rails_env),
          rails_groups: fetch(:rails_assets_groups),
          disable_database_environment_check: 1,
        ) do
          execute :rake, 'db:environment:set'
          execute :rake, 'db:schema:load'
        end
      end
    end
  end

  %w[start stop restart upgrade].each do |command|
    desc "#{command} unicorn (init.d)"
    task :"unicorn_#{command}" do
      on roles(:app) do
        unless fetch(:enable_unicorn)
          info 'Unicorn disabled'
          next
        end

        if fetch(:systemd_usage)
          command = 'reload' if command == 'upgrade'
          execute "sudo", "/usr/sbin/service unicorn_#{fetch(:application)}", command
        else
          execute "/etc/init.d/unicorn_#{fetch(:application)}", command
        end
      end
    end
  end

  %w[start stop restart reload].each do |command|
    desc "#{command} puma"
    task :"puma_#{command}" do
      on roles(:app) do
        unless fetch(:enable_puma)
          info 'Puma disabled'
          next
        end

        execute "sudo", "/usr/sbin/service puma_#{fetch(:application)}", command
      end
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} delayed_job process"
    task :"delayed_job_#{command}" do
      on roles(:app) do
        unless fetch(:enable_delayed_job)
          info 'Delayed job disabled'
          next
        end
          
        if fetch(:systemd_usage)
          execute "sudo", "/usr/sbin/service delayed_job_#{fetch(:application)}", command
        else
          execute "/usr/local/bin/#{fetch(:application)}.delayed_job", command
        end
      end
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} solid_queue process"
    task :"solid_queue_#{command}" do
      on roles(:app) do
        unless fetch(:enable_solid_queue)
          info 'Solid queue disabled'
          next
        end
          
        execute "sudo", "/usr/sbin/service solid_queue_#{fetch(:application)}", command
      end
    end
  end

  desc 'Symlink linked directories'
  task :linked_dirs do
    on release_roles :all do
      fetch(:more_linked_dirs).each do |target, source|
        target_path = release_path.join(target)
        source_path = shared_path.join(source)
        execute :mkdir, '-p', target_path.dirname
        next if test "[ -L #{target_path} ]"

        execute :rm, '-rf', target_path if test "[ -d #{target_path} ]"
        execute :ln, '-s', source_path, target_path
      end
    end
  end
end

namespace :load do
  task :defaults do
    rsync_excludes = %w[.git* spec rspec test Capfile config/deploy config/deploy.rb]
    set :rsync_options, "-azc --delete --delete-excluded --exclude #{rsync_excludes.join(' --exclude ')}"

    set :rvm_type, :user

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

before 'deploy:migrate', 'featureset:db_load_schema' unless ENV['FIRST_DEPLOYMENT'].nil?
after 'deploy:publishing', 'featureset:puma_reload'
after 'deploy:publishing', 'featureset:unicorn_upgrade'
after 'featureset:unicorn_upgrade', 'featureset:generate_static_500_html'
after 'featureset:unicorn_upgrade', 'featureset:generate_static_error_html'
after 'deploy:publishing', 'featureset:delayed_job_restart'
after 'deploy:publishing', 'featureset:solid_queue_restart'
after 'deploy:symlink:linked_dirs', 'featureset:linked_dirs'
