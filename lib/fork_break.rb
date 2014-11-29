require 'fork'
require 'fork_break/breakpoint_setter'
require 'fork_break/breakpoints'
require 'fork_break/process'

module ForkBreak
  class BreakpointNotReachedError < StandardError; end
end
