require 'fork'
require 'fork_break/breakpoint_setter'
require 'fork_break/breakpoints'
require 'fork_break/process'
require 'timeout'

module ForkBreak
  class BreakpointNotReachedError < StandardError; end
  class WaitTimeout < StandardError; end
end
