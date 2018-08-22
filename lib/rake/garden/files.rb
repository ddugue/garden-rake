
module Rake::Garden
  ##
  # Proxy for Dir Glob that decorates string with
  # a magic format method
  ##
  def directories(path, &block)
    Dir.glob(path).each do |f|
      String.send(:define_method, :magic_format) do
        self.gsub! /%[fnpxdX]/ do |s|
          case s.to_s
          when '%f'
            File.basename(f)
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
    end
  end

  ##
  # Decorator function to allow string interpolation of filenames
  ##
  def with_file(f, &block)
      String.send(:define_method, :magic_format) do
        self.gsub! /%[fnpxdX]/ do |s|
          case s.to_s
          when '%f'
            File.basename(f)
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
  end

  ##
  # Class used to decorate the each method with our magic_format method
  ##
  class FileSet < Set
    def each(&block)
      super do |f|
        with_file f, &block
      end
    end

    def >>(other)
      [self, other]
    end
  end
end

class String
  def >>(other)
    [self, other]
  end
end
class Array
  def >>(other)
    if self.length == 1
      [self, other]
    end
    self << other
  end
end
