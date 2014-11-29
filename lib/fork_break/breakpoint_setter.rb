module ForkBreak
  class BreakpointSetter
    def initialize(fork, debug = false)
      @fork = fork
      @next_breakpoint = :forkbreak_start
      @debug = debug
    end

    def <<(symbol)
      @fork.send_object(symbol)
      if symbol == @next_breakpoint
        @next_breakpoint = @fork.receive_object unless symbol == :forkbreak_end
        puts "#{@fork.pid} received #{@next_breakpoint}" if @debug
      end
    rescue EOFError => exception
      raise @fork.exception || exception
    end
  end
end
