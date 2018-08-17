lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'fork_break/version'

Gem::Specification.new do |gem|
  gem.authors       = ['Petter Remen', 'Pedro Carriço']
  gem.summary       =
    'Testing multiprocess behaviour is difficult and requires a way to synchronize processes at specific execution ' \
    'points. This gem allows the parent process to control the behaviour of child processes using breakpoints. It was' \
    'originally built for testing the behaviour of database transactions and locking mechanisms.'
  gem.description   = 'Fork with breakpoints for syncing child process execution'
  gem.homepage      = 'http://github.com/forkbreak/fork_break'
  gem.licenses      = ['MIT']
  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'fork_break'
  gem.require_paths = ['lib']
  gem.version       = ForkBreak::VERSION
  gem.required_ruby_version = '~> 2.2'
  gem.add_dependency 'fork', '= 1.0.1'
  gem.add_development_dependency 'rake', '~> 12.3.1'
  gem.add_development_dependency 'rspec', '~> 3.8.0'
  gem.add_development_dependency 'rubocop', '~> 0.58.2'
end
