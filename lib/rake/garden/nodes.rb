
class Leaf
  def each
    return enum_for(:each) unless block_given?
    yield self
  end
end

class Node < Leaf
  def initialize(nodes = [])
    @nodes = nodes
  end

  def each(&block)
    return enum_for(:each) unless block_given?
    @nodes.each &block
  end
end

class Process < Node
  def all(&block)
    return enum_for(:all) unless block_given?
    @nodes.each do |node|
      if node.is_a? Process
        node.input_files.each &block
        node.all &block
      else
        node.each &block
      end
    end
  end

  def each(&block)
    return enum_for(:each) unless block_given?
    output_files.a
  end
end
