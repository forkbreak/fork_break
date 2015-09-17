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

  it 'raises the process exception' do
    class MyException < StandardError; end

    process = ForkBreak::Process.new do
      raise MyException
    end

    expect { process.finish.wait }.to raise_error(MyException)
  end

  it 'raises a wait timeout eror when the process takes longer than the specified wait timeout' do
    process = ForkBreak::Process.new do
      sleep(1)
    end

    expect { process.finish.wait(timeout: 0.01) }.to raise_error(ForkBreak::WaitTimeout)
  end
end
