# frozen_string_literal: true

require 'rake/garden/fileawarestring'
require 'rake/garden/filepath'
require 'rake/garden/context'
require 'rake/early_time'

module Garden
  class Fileset
    include Enumerable
    include Dependable

    def initialize(files = [], default_since = nil)
      @files = files
      @default_since = default_since || Context.instance.default_since || Rake::EARLY
    end

    def <<(file)
      if file.is_a? String
        @files << Filepath.new(file)
      else
        @files << file
      end
    end

    ##
    # Iterate over each file and fileset that is contained inside this
    # fileset
    def each(&block)
      return enum_for(:each) unless block_given?
      @files.each &block
    end

    ##
    # Filter a fileset by extension
    # Returns a +Fileset+
    def ext(extension, &block)
      extension = ".#{extension}" unless extension.start_with? '.'
      fs = Fileset.new(select { |f| f.ext == extension })
      fs.each(&block) if block_given?
      fs
    end

    ##
    # Return files that have been modified since a specific date
    def since
    end

    class << self
      GLOB = Regexp.new(/^[^\*]*/)

      # Create a fileset from a glob
      def from_glob(glob)
        fileset = self.new
        directory_root = (GLOB.match(glob)[0] || '').to_s
        Context.instance.with_value :directory_root, directory_root do
          (Dir.glob glob).sort.each do |path|
            fileset << path
          end
        end
        fileset
      end
    end
  end

  # module Filepipe

  #   def input_files

  #   end
  # alias files

  #   def output_files
  #   end

  #   ##
  #   # Return all inputfiles
  #   def all_input_filse
  #   end
  # alias all
  # end

  # Represent a fileset that is built with a Glob
  # class GlobFileset < Fileset
  #   GLOB = Regexp.new(/^[^\*]*/)

  #   def initialize(glob)
  #     super
  #     @glob = glob.to_s
  #     @directory_root ||= (GLOB.match(@glob)[0] || '').to_s
  #   end

  #   def resolve
  #     super
  #     @files = (Dir.glob @glob).sort
  #   end
  # end

  # # Represent a 'set of set'
  # class FilesetGroup
  #   include Enumerable
  #   def initialize(*args)
  #     @filesets = []
  #     @orphans = Fileset.new

  #     append_fileset(args)
  #   end

  #   def append_fileset(fileset)
  #     if fileset.is_a? Fileset
  #       @filesets.unshift fileset
  #     elsif fileset.is_a? String
  #       str = FileAwareString.create(fileset)
  #       if str.glob?
  #         @filesets.unshift GlobFileset.new(str)
  #       else
  #         @orphans << str
  #       end
  #     elsif fileset.is_a? Enumerable
  #       fileset.each { |fs| append_fileset(fs) }
  #     end
  #   end

  #   def each(&block)
  #     return enum_for(:each) unless block_given?
  #     @filesets.each { |fs| fs.each(&block) }
  #     @orphans.each(&block)
  #   end
  # end
end
