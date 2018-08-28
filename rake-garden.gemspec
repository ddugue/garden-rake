
Gem::Specification.new do |s|
  s.name        = 'rake-garden'
  s.version     = '0.0.1'
  s.date        = '2017-11-10'
  s.summary     = 'Task extension for conditional execution'
  s.description = 'Automatically checks for task execution requirements via'\
                  ' inotify to make sure task executions only happen when'\
                  ' necessary'
  s.authors     = ['David Dugue']
  s.email       = 'ddugue@kumoweb.ca'
  s.files       = %x[git ls-files -z].split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # s.files       = ["lib/rake/garden.rb", "lib/rake/garden/logger.rb",
  #                  "lib/rake/garden/hooks.rb", "lib/rake/garden/chores.rb",
  #                  "lib/rake/garden/strace.rb",
  #                 ]
  s.require_paths = ["lib".freeze]
  s.homepage    = 'http://rubygems.org/gems/rake-garden'
  s.license     = 'MIT'
  # Dependencies
  s.add_runtime_dependency "msgpack", "~> 1.1", ">= 1.1.0"
  s.add_runtime_dependency "rb-inotify", "~> 0.9",  ">= 0.9.10"
  s.add_runtime_dependency "os", "~> 1.0",  ">= 1.0.0"
  s.add_runtime_dependency "colorize", "~> 0.8"

end
