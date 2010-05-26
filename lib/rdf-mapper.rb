module RDFMapper
  
  require 'rdf-xml'
  require 'rdf-sparql'

  autoload :Model,        'lib/model/base'
  autoload :Scope,        'lib/scope/model'
  autoload :Associations, 'lib/associations/base'
  autoload :Adapters,     'lib/adapters/base'
  autoload :HTTP,         'lib/util/http'
  autoload :Logger,       'lib/util/logger'
  
end


