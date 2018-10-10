# frozen_string_literal: true

module Garden
  ## String that can substitue part of itself to repla
  class FileAwareString
    attr_reader :file
    attr_reader :directory_root

    def initialize(directory_root, file, string)
      @directory_root = directory_root || "#{File.dirname(file)}/"
      @file = file
      @string = string

      # We keep the formatted attribute to make the conversion lazy and to
      # keep it happening more than once.
      @formatted = false
    end

    # Return the directory part of the path minus the directory root
    # Allows substitution in relative paths
    def directory_prefix
      @directory_prefix ||= @file.to_s\
                                 .sub(@directory_root, '')\
                                 .sub(File.basename(@file), '')
    end

    # Return wether this string is a glob pattern
    def glob?
      @string.include? '*'
    end

    # Format the string if it hasn't been formatted by replacing some special
    # character expression by part of the file
    # %f - Replace with file basename and relative directory pathy
    # %F - Replace ONLY with file basename
    # %b - Replace with file basename without extension and relative directory
    # %B - Replace only with file base name without extension
    # %x - Replace with file extension
    # %d - Replace with relative directory path
    # %D - Replace with full directory path
    # %p - Replace with full path
    def format
      return @string if @formatted
      @formatted = true
      @string.gsub!(/%[bBfFpxdD]/) do |s|
        case s.to_s
        when '%f' then directory_prefix + File.basename(@file)
        when '%F' then File.basename(@file)
        when '%b' then directory_prefix + File.basename(@file, '.*')
        when '%B' then File.basename(@file, '.*')
        when '%x' then File.extname(@file)
        when '%d' then
          directory_prefix.empty? ? @directory_root : directory_prefix
        when '%D' then File.dirname(@file)
        when '%p' then @file
        end
      end
      @string
    end

    def to_s
      format
    end

    def ==(other)
      return other == to_s if other.is_a? String
      return other.to_s == to_s if other.is_a? FileAwareString
      false
    end

    class << self
      attr_accessor :file
      attr_accessor :directory_root

      def with_file(file, directory_root = nil)
        if directory_root
          previous_root = self.directory_root
          self.directory_root = directory_root
        end
        previous_file = self.file
        self.file = file
        yield
        self.file = previous_file
        self.directory_root = previous_root if previous_root
      end

      def with_folder(folder, &block)
        with_file(nil, folder, &block)
      end

      ##
      # Shortcut function to create a file aware string based on the current context
      def create(string)
        new(self.directory_root, self.file, string)
      end

      def [](string)
        create(string)
      end
    end
  end
end
