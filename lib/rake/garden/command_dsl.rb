require 'pathname'

require 'rake/garden/commands/echo'
require 'rake/garden/commands/set'
require 'rake/garden/commands/unset'
require 'rake/garden/commands/cd'
require 'rake/garden/commands/cp'
require 'rake/garden/commands/sh'
require 'rake/garden/commands/mkdir'
require 'rake/garden/commands/daemon'

module Garden
  ##
  # Represent a dsl that allows to queue commands
  # commands
  module CommandsDSL
    attr_accessor :workdir # Actual work directory of the chore
    attr_accessor :env     # Environment variable passed to commands

    def initialize(*args)
      @queue = []
      @workdir = Pathname.new(Pathname.pwd)
      @env = {}
      super
    end

    ##
    # Queue command for execution
    def queue(cls, args, kwargs)
      args = args.to_a
      command = cls.new(*args, **kwargs)

      command.manager = self     if self.is_a? AsyncManager
      command.workdir = @workdir if @workdir
      command.env = @env.clone   if @env

      @logger.debug(" Queuing '#{command}'") if @logger

      @queue << command
      command
    end

    ##
    # Create synchronously a folder
    def mkdir(*args, **kwargs)
      queue MakeDirCommand, args, kwargs
    end

    ##
    # Echo a simple message in the async context
    def echo(*args, **kwargs)
      queue EchoCommand, args, kwargs
    end

    ##
    # Set variable environment
    # Can be used like set :VAR => value or set :VAR, value or set VAR:value
    def set(*args)
      queue SetCommand.new(self, *args)
    end

    ##
    # Unset an environment variable
    def unset(var)
      queue UnsetCommand.new(self, var)
    end

    ##
    # Change directory
    def cd(*args, **kwargs)
      queue ChangedirectoryCommand, args, kwargs
    end

    ##
    # Copy file -> location
    def cp(*args, **kwargs)
      queue CopyCommand, args, kwargs
    end

    ##
    # Run a shell command
    def sh(*args, **kwargs)
      queue ShCommand, args, kwargs
    end

    def strace(*args)
      queue StraceCommand.new(self, ShArgs.new(*args))
    end

    def daemon(cmd)
      queue DaemonCommand.new(self, cmd)
    end
  end
end
