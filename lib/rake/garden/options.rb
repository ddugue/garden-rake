# frozen_string_literal: true

require 'optparse'
require 'ostruct'

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
      @unparsable = []
      @parser = OptionParser.new
      parse
    end

    # Proxy for +OptionParser.on+, see +OptionParser+ documentation for usage
    def on(*args, &block)
      @parser.on(*args, &block)
    end

    # Parse or reparse arguments from the cli.
    #
    # Some tasks can then defer option handling later in the execution process
    def parse
      return self if @argv.empty?
      has_error = true
      args = @argv + @unparsable
      until args.empty? do
        begin
          @parser.parse! args
        rescue OptionParser::InvalidOption => e
          # We ignore invalid options as the option might not have been
          # added to our option parser yet. Unfortunately, it is not possible
          # to not make +OptionParser+ raise error
          invalid = e.to_s.sub(/invalid option:\s+/, '')
          @unparsable.push(invalid)
          @unparsable.push(args[0]) unless args[0].nil? or args[0].start_with? '-'
        end
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
