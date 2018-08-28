require 'rake/garden/ext/file'
require 'rake/garden/commands/sh'

module Rake::Garden
  ##
  # Abstract command that wraps a cp
  class CopyCommand < ShCommand
    def initialize(from, to)
      @from = from
      @to = to.format_with_file!
      super "mkdir -p #{Pathname.new(@to).dirname} && cp #{@from} #{@to}"
    end

    def skip?
      @skip = File.safe_mtime(@to) > File.safe_mtime(@from) if @skip.nil?
      @skip
    end

    def to_s
      "Copying #{@from} to #{@to}"
    end

    def output_files
      @skip ? nil : FileSet.new([@to])
    end
  end
end
