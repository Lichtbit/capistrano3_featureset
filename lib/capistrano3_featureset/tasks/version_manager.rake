RVM_SYSTEM_PATH = "/usr/local/rvm"
RVM_USER_PATH = "~/.rvm"

namespace :version_manager do
  desc "Prints the mise/RVM and Ruby version on the target host"
  task :check do
    on roles(fetch(:ruby_roles, :all)) do
      if fetch(:version_manager) == 'mise'

        # chcek ruby version
        ruby_version = fetch(:ruby_version)
        installed_rubies = capture(:mise, 'list', 'ruby', '--installed')
        unless installed_rubies.include?(ruby_version)
          error "Ruby #{ruby_version} is not installed via mise."
          error "Installed Rubies:"
          error installed_rubies
          error "Install with: mise install ruby@#{ruby_version}"
          raise Capistrano::Error, "Required Ruby #{ruby_version} is not installed"
        end

        # check env file
        env_file = "/home/#{fetch(:application)}/#{fetch(:application)}_env_vars"
        if test("[ -f #{env_file} ]")
          exported_vars = capture(
            :grep,
            '-nE',
            '^export[[:space:]]+',
            env_file,
            raise_on_non_zero_exit: false
          )

          unless exported_vars.empty?
            error "Environment file contains variables using 'export':"
            error exported_vars
            error "Please use plain assignments like: FOO=bar"
            raise Capistrano::Error, "Environment variables must not use 'export'"
          end
        else
          error "Environment file not found: #{env_file}"
          raise Capistrano::Error, "Required environment file is missing"
        end
      end

      if fetch(:log_level) == :debug
        if fetch(:version_manager) == 'mise'
          puts capture(:mise, "version")
        else
          puts capture(:rvm, "version")
          puts capture(:rvm, "current")
        end
        puts capture(:ruby, "--version")
      end
    end
  end

  task :hook do
    if fetch(:version_manager) == 'mise'
      env = fetch(:default_env, {})
      path = env.fetch(:PATH, '$PATH')

      SSHKit.config.default_env.merge!(path: "/home/#{fetch(:application)}/.local/bin:$PATH")
      SSHKit.config.default_env.merge!(mise_config_file: "/home/#{fetch(:application)}/#{fetch(:application)}.mise.toml")

      set :mise_path, "~/.local/bin/mise"

      SSHKit.config.command_map[:mise] = fetch(:mise_path)

      mise_prefix = "#{fetch(:mise_path)} exec ruby@#{fetch(:ruby_version)} --"
      fetch(:ruby_map_bins).each do |command|
        SSHKit.config.command_map.prefix[command.to_sym].unshift(mise_prefix)
      end
    else
      on roles(fetch(:ruby_roles, :all)) do
        rvm_path = fetch(:rvm_custom_path)
        rvm_path ||= case fetch(:rvm_type)
        when :auto
          if test("[ -d #{RVM_USER_PATH} ]")
            RVM_USER_PATH
          elsif test("[ -d #{RVM_SYSTEM_PATH} ]")
            RVM_SYSTEM_PATH
          else
            RVM_USER_PATH
          end
        when :system, :mixed
          RVM_SYSTEM_PATH
        else # :user
          RVM_USER_PATH
        end

        set :rvm_path, rvm_path
      end

      SSHKit.config.command_map[:rvm] = "#{fetch(:rvm_path)}/bin/rvm"

      rvm_prefix = "#{fetch(:rvm_path)}/bin/rvm #{fetch(:ruby_version)} do"
      fetch(:ruby_map_bins).each do |command|
        SSHKit.config.command_map.prefix[command.to_sym].unshift(rvm_prefix)
      end
    end
  end
end

Capistrano::DSL.stages.each do |stage|
  after stage, 'version_manager:hook'
  after stage, 'version_manager:check'
end
