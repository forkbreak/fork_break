# ForkBreak

[![Build Status](https://secure.travis-ci.org/forkbreak/fork_break.png)](http://travis-ci.org/forkbreak/fork_break) [![Dependency Status](https://gemnasium.com/forkbreak/fork_break.png)](https://gemnasium.com/forkbreak/fork_break) [![Gem Version](https://badge.fury.io/rb/fork_break.svg)](http://badge.fury.io/rb/fork_break) [![Code Climate](https://codeclimate.com/github/forkbreak/fork_break/badges/gpa.svg)](https://codeclimate.com/github/forkbreak/fork_break)

Testing multiprocess behaviour is difficult and requires a way to synchronize processes at
specific execution points. This gem allows the parent process to control the behaviour of child processes using
breakpoints. It was originally built for testing the behaviour of database transactions and locking mechanisms.

## Installation

Add this line to your application's Gemfile:

    gem 'fork_break'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fork_break

## Usage

A simple example

```ruby
process = ForkBreak::Process.new do |breakpoints|
  sleep(1)
  breakpoints << :after_sleep_1
  sleep(2)
  breakpoints << :after_sleep_2
end

def time(&block)
  before = Time.now
  block.call
  (Time.now - before).round
end

puts time { process.run_until(:after_sleep_1).wait } # => 1
puts time { process.run_until(:after_sleep_2).wait } # => 2
puts time { process.finish.wait } # => 0
```

You can also get access to the breakpoints by including ForkBreak::Breakpoints, allowing you to test
existing classes with minor changes. The following test the behaviour of using a file as a counter, with
and without file locks.

```ruby
class FileCounter
  include ForkBreak::Breakpoints

  def self.open(path, use_lock = true)
    file = File.open(path, File::RDWR|File::CREAT, 0600)
    return new(file, use_lock)
  end

  def initialize(file, use_lock = true)
    @file = file
    @use_lock = use_lock
  end

  def increase

    breakpoints << :before_lock

    @file.flock(File::LOCK_EX) if @use_lock
    value = @file.read.to_i + 1

    breakpoints << :after_read

    @file.rewind
    @file.write("#{value}\n")
    @file.flush
    @file.truncate(@file.pos)
  end
end

def counter_after_synced_execution(counter_path, with_lock)
  process1, process2 = 2.times.map do
    ForkBreak::Process.new do
      FileCounter.open(counter_path, with_lock).increase
    end
  end

  process1.run_until(:after_read).wait

  # process2 can't wait for read since it will block
  process2.run_until(:before_lock).wait
  process2.run_until(:after_read) && sleep(0.1)

  process1.finish.wait # Finish process1
  process2.finish.wait # Finish process2

  File.read(counter_path).to_i
end

puts counter_after_synced_execution("counter_with_lock",    true)  # => 2
puts counter_after_synced_execution("counter_without_lock", false) # => 1
```

There's also the possibility of adding a predefined timeout to the wait function and having it raise an exception.

```ruby
process = ForkBreak::Process.new do
  sleep(5)
end

process.finish.wait(timeout: 1) # will raise ForkBreak::WaitTimeout after 1 second
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
ForkBreak is released under the [MIT License](http://www.opensource.org/licenses/MIT).
