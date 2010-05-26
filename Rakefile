require 'rake'
require 'yard'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test library.'
Spec::Rake::SpecTask.new(:test) do |test|
  test.spec_files = Dir.glob('test/**/*_spec.rb')
  test.spec_opts << '--format specdoc'
end

desc 'Generate documentation.'
YARD::Rake::YardocTask.new(:doc) do |t|
  t.files   = ['lib/**/*.rb']
  t.options = ['--title=RDFMapper']
end

desc 'Build a gem package'
task :build_gem do
  system 'rm rdf-mapper-*.gem'
  system 'gem build .gemspec'
end

desc 'Install gem locally'
task :local_install do
  system 'sudo gem install --local rdf-mapper-*.gem'
end

desc 'Build and install gem locally'
task :install => [:build_gem, :local_install]
