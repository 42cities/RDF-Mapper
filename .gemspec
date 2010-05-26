Gem::Specification.new do |gem|
  
    gem.version            = File.read('VERSION').chomp
    gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')
    gem.name               = 'rdf-mapper'
    gem.rubyforge_project  = 'rdf-mapper'
    gem.homepage           = 'http://github.com/42cities/rdf-mapper/'
    gem.summary            = 'A Ruby ORM that is designed to play nicely with RDF data.'
    gem.description        = 'RDFMapper is a lightweight Ruby ORM that works with RDF data in a Rails-like fashion. Is supports XML, N-Triples, JSON formats, SPARQL and ActiveRecord as data sources.'
    gem.authors            = ['Alex Serebryakov']
    gem.email              = 'serebryakov@gmail.com'
    gem.platform           = Gem::Platform::RUBY
    gem.files              = %w(README.rdoc UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
    gem.require_paths      = %w(lib)
    gem.has_rdoc           = true
    gem.add_development_dependency 'rspec',   '>= 1.3.0'
    gem.add_runtime_dependency     'rdf',     '>= 0.1.1'
    gem.add_runtime_dependency     'rdf-xml', '>= 0.0.1'
    gem.add_runtime_dependency     'patron',  '>= 0.4.6'
    gem.post_install_message       = nil
    
end
