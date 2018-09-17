require 'rake/garden/filepath'

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
    return enum_for(:each) unless block_given?

    resolve if @pending

    previous_root = FileAwareString.folder_root
    previous_file = FileAwareString.file

    FileAwareString.folder_root = @root
    @files.each do |file|
      FileAwareString.file = file
      yield file
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
