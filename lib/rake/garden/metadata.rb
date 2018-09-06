require 'json'

module Garden
  ##
  # Recursive datastructure to fetch data from a metadata file
  ##
  class TreeDict
    def initialize(data = nil, parent = nil)
      @data = data || {}
      @parent = parent
      @namespaces = {}
    end

    ##
    # Return a sub division of this datastructure
    def namespace(name)
      # We return an existing namespace if it was already created
      return @namespaces[name.to_s] if @namespaces.key? name.to_s

      # We create a namespace and return it if it does not exist
      @namespaces[name.to_s] = if @data.key? name.to_s
                                 TreeDict.new(@data[name.to_s], self)
                               else
                                 TreeDict.new(nil, self)
                               end
    end

    ##
    # Return a single hash data tree
    ##
    def to_json(*)
      @data.merge(@namespaces).to_json
    end

    def save
      @parent.save if @parent
    end

    ##
    # Override of the default methods to access data
    def [](ind)
      @data[ind]
    end

    def []=(ind, value)
      @data[ind] = value
    end

    def key?(key)
      @data.key? key
    end

    def fetch(value, default)
      @data.fetch(value, default)
    end
  end

  ##
  # Stores Metadata in a Json file structure
  class JSONMetadata < TreeDict
    def initialize(filename)
      @filename = filename
      data = JSON.load(File.read(@filename)) if File.file?(@filename)
      super data
    end

    def save
      File.open(@filename, 'w+') { |file| JSON.dump(self, file) }
    end
  end
end
