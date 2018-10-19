require 'rake/garden/commands/sh'

module Garden
  ##
  # Represent the args that are sent to a copy command
  class MakeDirArgs < ShArgs
    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'mkdir'
      The acceptable forms for mkdir are the following:
      * mkdir 'folder'

    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length != 1
    end

    ##
    # Return the folder to create
    def folder
      @folder ||= format_file(get(0))
    end
  end

  ##
  # Abstract command that wraps a mkdir
  class MakeDirCommand < ShCommand
    @Args = MakeDirArgs

    def command
      "mkdir -p #{@args.folder}"
    end

    def should_skip
      File.directory?(@args.folder)
    end

    def to_s
      "Creating directory #{@args.folder}"
    end
  end
end
