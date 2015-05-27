module ForkBreak
  module Breakpoints
    def breakpoints
      ForkBreak::Process.breakpoint_setter
    end
  end
end
