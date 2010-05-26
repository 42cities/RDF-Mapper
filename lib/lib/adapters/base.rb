module RDFMapper
  module Adapters
    
    autoload :Rails,  'lib/adapters/rails'
    autoload :REST,   'lib/adapters/rest'
    autoload :SPARQL, 'lib/adapters/sparql'
    
    ##
    # Instantiates and returns an instance of an adapter. 
    #
    # @param [Symbol] name (:rails, :sparql, :rest)
    # @param [Object] cls subclass of RDFMapper::Model
    # @param [Hash] options options to pass on to the adapter constructor
    #
    # @return [Object] instance of an adapter
    ##
    def self.register(name, cls, options = {})
      self[name].new(cls, options)
    end
    
    ##
    # Returns adapter's class based on specified `name` (:rails, :sparql, :rest)
    #
    # @return [Object]
    ##
    def self.[](name)
      case name
        when :rails   then Rails
        when :sparql  then SPARQL
        when :rest    then REST
        else raise NameError, 'Adapter `%s` not recognized' % value.inspect
      end
    end
    
    ##
    # Parent class for all adapters. Contains default constructor method
    # and interface methods that each adapter should override.
    ##
    class Base
      
      ##
      # All adapters implement Logger
      ##
      include RDFMapper::Logger

      ##
      # Adapter implementation should override this method
      ##
      def load(query)
        raise NotImplementedError, 'Expected adapter to override `load`'
      end

      ##
      # Adapter implementation should override this method
      ##
      def save(instance)
        raise NotImplementedError, 'Expected adapter to override `save`'
      end

      ##
      # Adapter implementation should override this method
      ##
      def reload(instance)
        raise NotImplementedError, 'Expected adapter to override `save`'
      end

      ##
      # Adapter implementation should override this method
      ##
      def update(instance)
        raise NotImplementedError, 'Expected adapter to override `save`'
      end
      
      ##
      # Adapter implementation should override this method
      ##
      def create(instance)
        raise NotImplementedError, 'Expected adapter to override `save`'
      end
      
    end
  end
end