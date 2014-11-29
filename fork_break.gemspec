# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Petter Remen"]
  gem.email         = ["petter.remen@gmail.com"]
  gem.summary       = %q{Testing multiprocess behaviour is difficult and requires a way to synchronize processes at
specific execution points. This gem allows the parent process to control the behaviour of child processes using
breakpoints. It was originally built for testing the behaviour of database transactions and locking mechanisms. }
  gem.description   = %q{Fork with breakpoints for syncing child process execution}
  gem.homepage      = "http://github.com/remen/fork_break"
  gem.licenses      = ['MIT']

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fork_break"
  gem.require_paths = ["lib"]
  gem.version       = "0.1.2"
  gem.add_dependency "fork"              , "= 1.0.1"
  gem.add_development_dependency "rspec" , "= 3.1.0"
end
