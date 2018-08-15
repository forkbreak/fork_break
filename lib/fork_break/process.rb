module ForkBreak
  class Process
    class << self
      attr_accessor :breakpoint_setter
    end

    attr_reader :return_value

    @breakpoint_setter = NullBreakpointSetter.new

    def initialize(debug = false, &block)
      @debug = debug
      @fork = Fork.new(:return, :to_fork, :from_fork) do |child_fork|
        self.class.breakpoint_setter = breakpoints = BreakpointSetter.new(child_fork, debug)

        breakpoints << :forkbreak_start
        begin
          returned_value = block.call(breakpoints)
          breakpoints << :forkbreak_end
        rescue Exception => e
          breakpoints << e
          raise
        end

        self.class.breakpoint_setter = nil
        returned_value
      end
    end

    def run_until(breakpoint)
      @next_breakpoint = breakpoint
      @fork.execute unless @fork.pid
      puts "Parent is sending object #{breakpoint} to #{@fork.pid}" if @debug
      @fork.send_object(breakpoint)
      self
    end

    def wait(options = {})
      # A timeout value of nil will execute the block without any timeout
      Timeout.timeout(options[:timeout], WaitTimeout) do
        loop do
          brk = @fork.receive_object
          puts "Parent is receiving object #{brk} from #{@fork.pid}" if @debug

          @return_value = @fork.return_value if brk == :forkbreak_end

          if brk == @next_breakpoint
            return self
          elsif brk.is_a?(Exception)
            raise brk
          elsif brk == :forkbreak_end
            raise BreakpointNotReachedError, "Never reached breakpoint #{@next_breakpoint.inspect}"
          end
        end
      end
    rescue EOFError => exception
      raise @fork.exception || exception
    end

    def finish
      run_until(:forkbreak_end)
    end
  end
end
