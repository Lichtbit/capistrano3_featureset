lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'capistrano3_featureset'
  spec.version       = '1.0.0'
  spec.authors       = ['Georg Limbach', 'Tom Armitage', 'Stefan Daschek']
  spec.email         = ['georg.limbach@lichtbit.com']

  spec.summary       = 'Capistrano3 feature set'
  spec.description   = 'Capistrano3 feature set'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) { `git ls-files -z`.split("\x0") }
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '~> 3.0'
  spec.add_dependency 'capistrano-rails'
  spec.add_dependency 'capistrano-rvm'
  spec.add_dependency 'ed25519' #  to use modern ssh key ciphers
  spec.add_dependency 'bcrypt_pbkdf' #  to use modern ssh key ciphers
end
