
# frozen_string_literal: true

# Adds lightweight, toggleable debug tracing to any including model.
# When `debug_mode` is enabled, `private_ghost_trace` prints a formatted block to
# STDOUT and `Rails.logger.debug`, including a short call stack to help follow
# the execution flow.
#
# @example Toggle tracing for a model in Rails console
#   # In your terminal (bin/rails c)
#   User.debug_mode = false  # All User traces stop
#   User.debug_mode = true   # All User traces start again
#
# @!attribute [rw] debug_mode
#   @return [Boolean] true to enable tracing; false to silence it. Default: true.
module GhostTraceable
  extend ActiveSupport::Concern

  included do
    # This makes the switcher available to any model that includes this concern
    class_attribute :debug_mode, default: true
  end

  # This block adds methods to the Class itself (e.g., User.trace)
  class_methods do
    # Class-level alias for the trace logic
    # @param (see #private_ghost_trace)
    def private_ghost_class_trace(message, trace: true)
      # We create a "dummy" instance just to run the logic,
      # or we move the logic to a shared place.
      new.send(:private_ghost_trace, message, trace: trace)
    end
  end


  private

  # Outputs a formatted debug block to the console and Rails log.
  # Includes up to 3 recent caller frames to clarify execution flow.
  #
  # @param message [String] A label or data string to include in the block.
  # @param trace [Boolean] Whether to print a short caller backtrace. Defaults to true.
  # @return [void]
  # @example Basic usage inside a model method
  #   private_ghost_trace("Loading user profile", trace: true)
  # @note No-op when `debug_mode` is false.
  def private_ghost_trace(message, trace: true)
    return unless debug_mode

    border = "=" * 60
    header = "[GHOST-DEBUG] @ #{Time.current.strftime('%H:%M:%S')}"

    output = StringIO.new
    output.puts "\n#{border}"
    output.puts header
    # 'self' here refers to whatever object is using the concern (User, Session, etc.)
    output.puts "OBJECT: #{self.class} (ID: #{respond_to?(:id) ? id : 'N/A'})"
    output.puts "MESSAGE: #{message}"

    if trace
      output.puts "TRACE (Last 3 steps):"
      output.puts caller[1..3].map { |line| "  ↳ #{line.to_s.truncate(120)}" }
    end

    output.puts border

    final_string = output.string
    puts final_string
    Rails.logger.debug(final_string)
  end
end
