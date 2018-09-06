require 'rake/garden/commands/sh'

module Garden
  ##
  # Abstract command that wraps a mkdir
  class MakeDirCommand < ShCommand
    def initialize(folder)
      @folder = folder.format_with_file!
      super "mkdir -p #{@folder}"
    end

    def skip?
      @skip = File.directory?(@folder) if @skip.nil?
      @skip
    end

    def to_s
      "Creating directory #{@folder}"
    end

    def output_files
      nil
    end
  end
end
