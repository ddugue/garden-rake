
module Garden
  ##
  # Command that spawns a background process
  class DaemonCommand < Command
    def initialize(cmd)
      @cmd = cmd
      @metadata = metadata.namespace("daemons")
      @pid = @metadata.fetch(@cmd, nil)
      super
    end

    def process_exist?
      return false if @pid.nil?
      begin
        Process.getpgid(@pid)
        true
      rescue Errno::ESRCH
        false
      end
    end

    def skip?
      @skip = process_exist? if @skip.nil?
      @skip
    end

    def run(order)
      super
      unless skip?
        start = Time.now
        pid = spawn(@cmd, [:out, :err] => '/dev/null')
        Process.detach pid
        @time = Time.now - start
        @metadata[@cmd] = pid
      end
    end

    def log(logger, prefix = nil)
      super
      whitespace = ' ' * (7 + (prefix.nil? ? 0 : 3))
      logger.debug "#{whitespace}Current PID: #{@pid}"
    end

    def to_s
      "Spawning process '#{@cmd}'"
    end
  end
end
