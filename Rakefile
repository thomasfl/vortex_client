require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "vortex_client"
    gem.summary = %Q{Vortex CMS client}
    gem.description = %Q{Utility for managing content on Vortex web content management system through webdav}
    gem.email = "thomas.flemming@usit.uio.no"
    gem.homepage = "http://github.com/thomasfl/vortex_client"
    gem.authors = ["Thomas Flemming"]
    gem.executables = ["vrtx-sync"]
    gem.add_dependency "net_dav", ">= 0.5.0"
    gem.add_dependency "highline", ">= 1.5.1"
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.files.include %w(lib/vortex_client.rb lib/vortex_client/string_utils.rb lib/vortex_client/item_extensions.rb bin/vrtx-sync)
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "vortex_client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
