require 'open3'
require 'colorize'

module Rake::Garden
  class Stracer
    def initialize(command)
      @command = command
    end

    def file_hash
      return "/tmp/#{@command.hash}"
    end

    def command()
      return "strace -e file -o #{file_hash} #{@command}"
    end

    def parse(output)

      output.each do |line|
        matches = /opena?t?\(([^,\)]*),\s*([^,\)]*)(?:,\s*([^,\)]*))?\)/.match line
        if matches
          is_relative = matches[1] == 'AT_FDCWD'
          path = matches[-1] ? matches[-2] : matches[-3]
          path.gsub!('"', '')
          flags = matches[-1] ? matches[-1] : matches[-2]
          flags = flags.split('|')
          puts "#{is_relative} #{path} @ '#{flags}'"
        end
      end
    end

    def run()
      Open3.popen3(command) {|stdin, stdout, stderr, wait_thr|
        exit_status = wait_thr.value # Process::Status object returned.
        if exit_status != 0
          $stderr.puts "There was a problem running command: '#{@command}'".red
          $stderr.puts "############ COMMAND OUTPUT ###############".red
          stderr.each do |line|
            $stderr.puts line.red
          end
          exit(1)
        end

        parse(File.open file_hash, "r")
      }
    end
  end
end
