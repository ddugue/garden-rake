# frozen_string_literal: true

require 'rake/garden/commands/sh'

module Garden
  ##
  # Represent the args that are sent to a copy command
  class CopyArgs < ShArgs
    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'cp'
      The acceptable forms for cp are the following:
      * cp 'from' >> 'to' (where from and to are both path)

    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length != 2
      @input ||= format_file(get(0))
      @output ||= format_file(get(-1))
    end
  end

  ##
  # Abstract command that wraps a cp
  class CopyCommand < ShCommand
    @Args = CopyArgs

    ##
    # Return input files based on the provided output files
    def input_files
      @input_files ||= to_file(@args.input)
    end

    ##
    # Return output files based on the provided output files
    def output_files
      @output_files ||= to_file(@args.output)
    end

    def command
      "mkdir -p #{input_files.directory} && cp #{input_files} #{output_files}"
    end

    def to_s
      "Copying #{@args.input} to #{@args.output}"
    end
  end
end
