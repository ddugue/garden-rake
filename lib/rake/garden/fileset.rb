# frozen_string_literal: true

require 'rake/garden/filepath'
require 'rake/garden/context'
require 'rake/early_time'

module Garden
  # Represent a collection of +Fileset+ and files
  class Fileset
    include Enumerable

    def initialize(files = [])
      @files = files
    end

    def <<(file)
      @files << (file.is_a?(String) ? Filepath.new(file) : file)
    end

    # To support command args with file object, see +command_args+
    def >>(other)
      d = [self, other]
      d.is_args = true
      d
    end

    ##
    # Iterate over each file and fileset that is contained inside this
    # fileset
    def each(&block)
      return enum_for(:each) unless block_given?
      @files.each { |f| f.each(&block) }
    end

    ##
    # Return the full length
    def length
      to_a.length
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
    def since(date = nil, &block)
      since_date = date || Context.instance.default_since || Rake::EARLY
      fs = Fileset.new(select { |f| f.mtime > since_date })
      fs.each(&block) if block_given?
      fs
    end
    alias changed since

    class << self
      GLOB = Regexp.new(/^[^\*]*/)

      # Create a fileset from a glob
      def from_glob(glob)
        fileset = new
        directory_root = (GLOB.match(glob.to_s)[0] || '').to_s

        Context.instance.with_value :directory_root, directory_root do
          (Dir.glob glob).sort.each do |path|
            fileset << path
          end
        end
        fileset
      end
    end
  end
end
