DEBUG = ENV.fetch("DEBUG", "false") == "true"
require 'rake'
if DEBUG
  require 'json'
else
  require 'msgpack'
end

require 'rb-inotify'
module Rake::Garden
  class Logger
    include Singleton
    def initialize
      @start = Time.now
    end

    def verbose?; ENV.fetch("VERBOSE", "true") == "true"; end

    def render_time(time)
      time < 1 ? "#{(time * 1000).round(2)}ms" : "#{time.round(2)}s"
    end

    # Start a timer
    def start(); @time = Time.now; end
    def stop(); @time = nil; end

    # Log time since start on top of total time
    def log(text)
      if verbose?
        exec_time = render_time(@start.nil? ? 0 : Time.now - @time)
        total_time = render_time(Time.now - @start)
        puts "[#{exec_time} / #{total_time}] #{text}"
      end
    end
  end

  class Metadata
    include Singleton
    # Returns wether we use a JSON file (debug mode) or a msgpack file
    def json?; DEBUG; end

    def filename()
      @filename ||= ENV.fetch("GARDEN_FILE", json? ? ".garden.json" : ".garden")
    end

    # Return the hash representing the metadata
    # Metadata is a direct representation of its underlying data
    def data; @data ||= load; end
    def [](ind); data[ind]; end
    def []=(ind, value); data[ind] = value; end
    def key?(key); data.key? key; end
    def fetch(value, default); data.fetch value, default; end

    # Load the Message pack (or JSON file) and returns metadata
    def load()
      Logger.instance.start
      file = File.file?(filename) ? File.read(filename) : nil
      return Hash.new if file.nil?
      return JSON.load file if json?
      return MessagePack.unpack file
    ensure
      log "Load metadata #{filename}"
    end

    # Save the Metadata information to the filename
    def save()
      Logger.instance.start
      File.open filename, "w+" do |file|
        json? ? JSON.dump(data, file) : MessagePack.dump(data, file)
        log "Saved metadata #{filename}"
      end
    end
  end


  class Executor
    def initialize(command)
      @logger = Logger.instance
      @metadata = Metadata.instance
      @command = command

      @dependencies = Set.new
      @outputs = Set.new
    end

    def time_of_file(f); File.mtime(f).to_i if File.file? f; end

    def execute?()
      results = @metadata.fetch(@command, {"dependencies" => Array.new, "outputs" => Array.new} )
      dep_times = results["dependencies"].map { |x| time_of_file x }.reject { |x| x.nil? }
      out_times = results["outputs"].map { |x| time_of_file x }
      if out_times.any? { |x| x.nil? }
        return true
      elsif dep_times.any? and out_times.any?
        return out_times.min < dep_times.max
      end
      return true
    end

    # Return directories to watch when calling this task
    def directories()
      [Dir.pwd]
    end

    # Asynchronously watch for files
    def watch
      notifier = INotify::Notifier.new
      thr = Thread.new do
        directories.each do |directory|
          notifier.watch(directory, :access, :create, :modify, :recursive) do |event|
            if event.flags.include? :access
              @dependencies.add event.absolute_name
            else
              @outputs.add event.absolute_name
            end
          end
        end
        notifier.run
      end
      return (lambda do
                thr.exit
                notifier.close
              end)
    end

    def execute()
      @logger.start

      return log "Skipped #{@command}" if !execute?
      close = watch
      system @command
      close.call

      @metadata[@command] = @metadata.fetch(@command, Hash.new)
      @metadata[@command]["dependencies"] = @dependencies.to_a
      @metadata[@command]["outputs"] = @outputs.to_a

      return log "Executed #{@command}"
    end
  end

  # Shortcut functions
  def log(text); Logger.instance.log(text); end
  def execute(command)
    exec = Executor.new(command)
    exec.execute()
  end

  at_exit { Metadata.instance.save() }
end
