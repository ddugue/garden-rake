# frozen_string_literal: true

require 'rake/garden/fileawarestring'

module Garden
  class Fileset
    include Enumerable

    attr_reader :directory_root

    def initialize(*)
      @files = []
      @pending = true
      @directory_root = nil
    end

    def resolve
      @pending = false
    end

    def <<(file)
      if file.is_a? Array
        @files = file
      else
        @files << file
      end
    end

    def each
      return enum_for(:each) unless block_given?

      resolve if @pending

      FileAwareString.with_folder @directory_root do
        @files.each do |file|
          FileAwareString.with_file file do
            yield file
          end
        end
      end
    end
  end

  # Represent a fileset that is built with a Glob
  class GlobFileset < Fileset
    GLOB = Regexp.new(/^[^\*]*/)

    def initialize(glob)
      super
      @glob = glob.to_s
      @directory_root ||= (GLOB.match(@glob)[0] || '').to_s
    end

    def resolve
      super
      @files = (Dir.glob @glob).sort
    end
  end

  # Represent a 'set of set'
  class FilesetGroup
    include Enumerable
    def initialize(*args)
      @filesets = []
      @orphans = Fileset.new

      append_fileset(args)
    end

    def append_fileset(fileset)
      if fileset.is_a? Fileset
        @filesets.unshift fileset
      elsif fileset.is_a? String
        str = FileAwareString.create(fileset)
        if str.glob?
          @filesets.unshift GlobFileset.new(str)
        else
          @orphans << str
        end
      elsif fileset.is_a? Enumerable
        fileset.each { |fs| append_fileset(fs) }
      end
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      @filesets.each { |fs| fs.each(&block) }
      @orphans.each(&block)
    end
  end
end
