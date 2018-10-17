# frozen_string_literal: true

require 'rake/garden/context'

# Extending String to add a - method
class String
  def -(other)
    return self if other.nil?
    return self if other.empty?
    return sub(other, '') if other.is_a? String

    raise NoMethodError
  end
end

module Garden
  # Class that represent a filepath
  class Filepath
    attr_reader :path
    attr_reader :directory_root

    def initialize(path, directory_root = nil)
      @path = path
      @directory_root = directory_root || context.directory_root
    end

    # Return the extension of the path
    def ext
      File.extname(@path)
    end

    # Return the file name (basename + ext)
    def name
      File.basename(@path)
    end

    # Return the file name without extension
    def basename
      File.basename(@path, '.*')
    end

    # Represent the relative path of the directory
    def relative_directory
      return '' unless @directory_root
      @path - @directory_root - name
    end

    # Directory of the path
    def directory
      File.dirname(@path) + '/'
    end

    # Return the date of modification of the file if it exist
    def mtime
      File.exist?(@path) ? File.mtime(@path) : nil
    end

    # Return a global context object to extract global state
    # it allows us to set a default shared variable for
    # directory root that is set anywhere in the call stack hierarchy
    # See +each+
    def context
      Context.instance
    end

    def each
      return enum_for(:each) unless block_given?
      context.with_value :directory_root, directory_root do
        context.with_value :file, self do
          yield self
        end
      end
    end

    def to_s
      @path
    end

    def ==(other)
      return other == @path if other.is_a? String
      return other.to_s == to_s if other.is_a? Filepath
      false
    end

    # Format a string by replacing some special
    # character expression by part of the filepath
    # %f - Replace with file basename and relative directory pathy
    # %F - Replace ONLY with file basename
    # %b - Replace with file basename without extension and relative directory
    # %B - Replace only with file base name without extension
    # %x - Replace with file extension
    # %d - Replace with relative directory path
    # %D - Replace with full directory path
    # %p - Replace with full path
    def format(string)
      string.gsub(/%[bBfFpxdD]/) do |s|
        case s
        when '%f' then relative_directory + name
        when '%F' then name
        when '%b' then relative_directory + basename
        when '%B' then basename
        when '%x' then ext
        when '%d' then relative_directory.empty? ? directory : relative_directory
        when '%D' then directory
        when '%p' then @path
        end
      end
    end

    class << self
      # Return wether the string might be a filepath or a glob
      def is_file?(string)
        return true if string.instance_of? Filepath
        return false unless string.instance_of? String
        (string.include? '.')\
        || (string.include? '/') \
        || (string.include? '*')
      end
    end
  end
end
