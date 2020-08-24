require 'spec_helper'
require 'tmpdir'

describe ForkBreak::Process do
  it 'works as intented' do
    Dir.mktmpdir do |tmpdir|
      first_file = File.join(tmpdir, 'first_file')
      second_file = File.join(tmpdir, 'second_file')
      process = ForkBreak::Process.new do |breakpoints|
        FileUtils.touch(first_file)
        breakpoints << :after_first_file
        FileUtils.touch(second_file)
      end
      expect(File.exist?(first_file)).to be_falsey
      expect(File.exist?(second_file)).to be_falsey

      process.run_until(:after_first_file).wait
      expect(File.exist?(first_file)).to be_truthy
      expect(File.exist?(second_file)).to be_falsey

      process.finish.wait
      expect(File.exist?(first_file)).to be_truthy
      expect(File.exist?(second_file)).to be_truthy
    end
  end

  it 'raises an error (on wait) if a breakpoint is not encountered' do
    foo = ForkBreak::Process.new do |breakpoints|
      breakpoints << :will_not_run if false # rubocop:disable LiteralInCondition
    end
    expect do
      foo.run_until(:will_not_run).wait
    end.to raise_error(ForkBreak::BreakpointNotReachedError)
  end

  it 'works for the documentation example' do
    class FileCounter
      include ForkBreak::Breakpoints

      def self.open(path, use_lock = true)
        file = File.open(path, File::RDWR | File::CREAT, 0600)
        new(file, use_lock)
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
        ForkBreak::Process.new { FileCounter.open(counter_path, with_lock).increase }
      end

      process1.run_until(:after_read).wait

      # process2 can't wait for read since it will block
      process2.run_until(:before_lock).wait
      process2.run_until(:after_read) && sleep(0.1)

      process1.finish.wait # Finish process1
      process2.finish.wait # Finish process2

      File.read(counter_path).to_i
    end

    Dir.mktmpdir do |tmpdir|
      counter_path = File.join(tmpdir, 'counter')

      expect(counter_after_synced_execution(counter_path, true)).to eq(2)

      File.unlink(counter_path)
      expect(counter_after_synced_execution(counter_path, false)).to eq(1)
    end
  end

  it 'ignores breakpoints when running outside a ForkBreak process' do
    class Foo
      include ForkBreak::Breakpoints

      def bar
        breakpoints << :test
        'baz'
      end
    end

    expect(Foo.new.breakpoints).to be_kind_of(ForkBreak::NullBreakpointSetter)
    expect { Foo.new.bar }.to_not raise_error
    expect(Foo.new.bar).to eq('baz')
  end

  it 'raises the process exception' do
    class MyException < StandardError; end

    process = ForkBreak::Process.new do
      raise MyException
    end

    expect { process.finish.wait }.to raise_error(MyException)
  end

  it 'raises process exception when waiting on breakpoints' do
    class MyException < StandardError; end

    class FileLock
      include ForkBreak::Breakpoints

      def initialize(path)
        @file = File.open(path, File::RDWR | File::CREAT, 0600)
      end

      def set_once
        breakpoints << :before_lock
        @file.flock(File::LOCK_EX)
        value = @file.read.to_i
        breakpoints << :after_read
        raise MyException if value > 0
        @file.rewind
        @file.write("1\n")
        @file.flush
        @file.truncate(@file.pos)
      end
    end

    Dir.mktmpdir do |tmpdir|
      lock_path = File.join(tmpdir, 'lock')

      process_1, process_2 = 2.times.map do
        ForkBreak::Process.new { FileLock.new(lock_path).set_once }
      end

      expect do
        process_1.run_until(:after_read).wait
        process_2.run_until(:before_lock).wait
        process_2.run_until(:after_read) && sleep(0.1)
        process_1.finish.wait
        process_2.finish.wait
      end.to raise_error(MyException)

      File.unlink(lock_path)
    end
  end

  it 'raises process exception quickly when waiting on breakpoints' do
    class MyException < StandardError; end

    class Raiser
      include ForkBreak::Breakpoints

      def run
        raise MyException
        breakpoints << :after_raise
      end
    end

    process = ForkBreak::Process.new { Raiser.new.run }

    expect do
      process.run_until(:after_raise) && sleep(0.1)
      process.finish.wait
    end.to raise_error(MyException)
  end

  it 'raises a wait timeout error when the process takes longer than the specified wait timeout' do
    process = ForkBreak::Process.new do
      sleep(1)
    end

    expect { process.finish.wait(timeout: 0.01) }.to raise_error(ForkBreak::WaitTimeout)
  end

  it 'keeps the return value of the process' do
    class Foo
      include ForkBreak::Breakpoints

      def bar
        'baz'
      end
    end

    process = ForkBreak::Process.new { Foo.new.bar }.finish.wait

    expect(process.return_value).to eq('baz')
  end
end
