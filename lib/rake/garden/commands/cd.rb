# frozen_string_literal: true

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden
  ##
  # Represent the args for the cmmand CD
  class CdArgs < CommandArgs
    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'cd'
      The acceptable forms for cd are the following:
      * cd 'folder' (to change working directory for subsequent commands)
    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'
    INVALID_COMMAND = 'Command argument is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length.zero? || length > 1
    end

    ##
    # Return a fileset group for input files
    def folder
      @folder ||= begin
        f = format_file(get(0))
        f += '/' unless f.end_with? '/'
        f
      end
    end
  end

  ##
  # Command that represents a change directory
  class ChangedirectoryCommand < Command
    @Args = CdArgs

    def workdir=(value)
      @manager.workdir = value.join(@args.folder)
    end

    def to_s
      "Changing directory to #{@args.folder}"
    end
  end
end
