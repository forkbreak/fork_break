require_relative 'lib/fork_break/version'

Gem::Specification.new do |gem|
  gem.authors       = ['Petter Remen']
  gem.email         = ['petter.remen@gmail.com']
  gem.summary       =
    'Testing multiprocess behaviour is difficult and requires a way to synchronize processes at specific execution ' \
    'points. This gem allows the parent process to control the behaviour of child processes using breakpoints. It was' \
    'originally built for testing the behaviour of database transactions and locking mechanisms.'
  gem.description   = 'Fork with breakpoints for syncing child process execution'
  gem.homepage      = 'http://github.com/remen/fork_break'
  gem.licenses      = ['MIT']

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.name          = 'fork_break'
  gem.require_paths = ['lib']
  gem.version       = ForkBreak::VERSION
  gem.add_dependency 'fork', '= 1.0.1'
  gem.add_development_dependency 'rspec', '>= 3.1.0'
  gem.add_development_dependency 'rubocop', '>= 0.27.1'
end
