require 'rake'
require 'fileutils'

def gemspec_name
  @gemspec_name ||= Dir['*.gemspec'][0]
end

def gemspec
  @gemspec ||= eval(File.read(gemspec_name), binding, gemspec_name)
end

desc "Build the gem"
task :gem=>:gemspec do
  sh "gem build #{gemspec_name}"
  FileUtils.mkdir_p 'pkg'
  FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", 'pkg'
end

desc "Install the gem locally"
task :install => :gem do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

desc "Generate the gemspec"
task :generate do
  puts gemspec.to_ruby
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end

desc 'Run tests'
task :test do |t|
  sh 'rspec spec'
end

task :default => :test
