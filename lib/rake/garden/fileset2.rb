
def format_string_with_file(root, file, string)
  string.gsub!(/%[bBfFnpxdDX]/) do |s|
    prefix = root ? file.to_s.sub(root, '').sub(File.basename(file), '') : ''
    case s.to_s
    when '%f' then prefix + File.basename(file)
    when '%F' then File.basename(file)
    when '%b' then prefix + File.basename(file, '.*')
    when '%B' then File.basename(file, '.*')
    when '%x' then File.extname(file)
    when '%d' then prefix.empty? ? "#{File.dirname(file)}/" : prefix
    when '%D' then File.dirname(file)
    when '%n' then file.pathmap('%n')
    when '%X' then file.pathmap('%X')
    when '%p' then file
    end
  end
end

##
# Safe remove a method from a class
def remove_method_from_class(cls, method_name)
  return unless cls.method_defined? method_name
  cls.remove_method method_name
end
class Fileset
  include Enumerable

  def initialize(*args)
    @files = []
    @pending = true
    @root = nil
  end

  def resolve
    @pending = false
  end

  def <<(file)
    @files << file
  end

  def each
    return enum_for(:each) unless block_given? # Sparkling magic!

    resolve if @pending
    @files.each do |file|
      String.send(:define_method, :_format_with_file) do
        format_string_with_file(@root, file, self)
      end
      yield file
      remove_method_from_class(String, :_format_with_file)
    end
  end
end

class GlobFileset < Fileset

end

class FileGroup
  include Enumerable

  def initialize(*args)
  end


end
