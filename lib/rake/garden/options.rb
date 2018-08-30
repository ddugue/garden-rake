# frozen_string_literal: true

require 'optparse'

module Garden
  ##
  # Global scope object used to pass parameters and args to different tasks
  #
  # Options object is especially useful when configuring the executing context
  # based on some flags. This context is then passed to each chore in the
  # rakefile
  class Option < OpenStruct
    def initialize(argv = ARGV)
      super()
      @argv = suffix_argv argv
      @parser = OptionParser.new
      parse
    end

    # Proxy the +ENV+ rake object for a unified access
    def env
      ENV
    end

    # Proxy for +OptionParser.on+, see +OptionParser+ documentation for usage
    def on(*args, **kwargs, &block)
      @parser.on(*args, **kwargs, &block)
    end

    # Parse or reparse arguments from the cli.
    #
    # Some tasks can then defer option handling later in the execution process
    def parse
      return self if @argv.empty?
      begin
        @parser.parse @argv
      rescue OptionParser::InvalidOption
      end
      self
    end

    private

    # Return the second part passed after '--' in the ARGV (or [] if no '--')
    def suffix_argv(argv)
      return [] unless argv.include? '--'
      split = argv.join(' ').split(' -- ')
      split[-1].split ' '
    end
  end
end
