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
      * cd 'folder', CMD (to change working directory for CMD)
    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'
    INVALID_COMMAND = 'Command argument is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length.zero? || length > 2
    end

    ##
    # Return a fileset group for input files
    def folder
      return format_file(get(0))
    end

    ##
    # Return the c
    def command
      return if length < 2
      cmd = get(1)
      raise ParsingError.new(self, INVALID_CMD) unless cmd.is_a?(Command)
      cmd
    end
  end

  ##
  # Command that represents a change directory
  class ChangedirectoryCommand < Command
    @Args = CdArgs

    def parse_args(args, kwargs)
      parsed_args = super

      @command = parsed_args.command
      @folder = parsed_args.folder
      @folder += '/' unless @folder.end_with? '/'
      parsed_args
    end

    def workdir=(value)
      if @command
        @command.workdir = value.join(@folder)
      elsif @manager
        @manager.workdir = value.join(@folder)
      end
    end

    def to_s
      "Changing directory to #{@folder}"
    end
  end
end
