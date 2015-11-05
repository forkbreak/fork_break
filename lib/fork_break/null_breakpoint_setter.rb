module ForkBreak
  class NullBreakpointSetter
    def <<(*)
      # no-op
    end
  end
end
