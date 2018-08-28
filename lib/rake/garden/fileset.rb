require 'rake/garden/command_args'
require 'rake/garden/ext/string'

module Garden
  ##
  # Decorator function to allow string interpolation of filenames
  ##
  def with_file(f, &block)
    String.send(:define_method, :_format_with_file) do
      self.gsub! /%[bfnpxdX]/ do |s|
        case s.to_s
        when '%f'
          File.basename(f)
        when '%b'
          File.basename(f, '.*')
        when '%n'
          f.pathmap('%n')
        when '%x'
          File.extname(f)
        when '%d'
          File.dirname(f)
        when '%X'
          f.pathmap('%X')
        when '%p'
          f
        end
      end
    end
    block.call f
    String.remove_method(:_format_with_file) if String.method_defined? :_format_with_file
  end

  ##
  # Class used to decorate the each method with our magic_format method
  ##
  class FileSet < Set
    ##
    # Fix to prevent ruby from memoizing magic_format when calling any?
    def any?
      super
      String.remove_method(:_format_with_file) if String.method_defined? :_format_with_file
    end

    def each(&block)
      super do |f|
        if File.file? f
          with_file f, &block
        end
      end
    end

    def format_with_file!
      self
    end

    def >>(other)
      Args.new self.format_with_file!, other.format_with_file!
    end
  end
end
