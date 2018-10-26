require 'rake/garden/commands/sh'
require 'rake/garden/command_args'

module Garden
  ##
  # Represent the args that are sent to a copy command
  class MakeDirArgs < CommandArgs
    attr_reader :folder

    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'mkdir'
      The acceptable forms for mkdir are the following:
      * mkdir 'folder'
      * mkdir 'folder', :async (to execute mkdir asynchronously)

    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length.zero?
      @folder ||= format_file(get(0))
    end

    ##
    # Return wether the mkdir is async
    def async?
      @args.include? :async
    end
  end

  ##
  # Abstract command that wraps a mkdir
  class MakeDirCommand < ShCommand
    @Args = MakeDirArgs

    def command
      "mkdir -p #{@args.folder}"
    end

    ##
    # Return output files based on the provided output files
    def output_files
      @output_files ||= Fileset.new()
    end

    def should_skip
      File.directory?(@args.folder)
    end

    def process
      super
      # result unless @args.async?
    end

    def to_s
      "Creating directory #{@args.folder}"
    end
  end
end
