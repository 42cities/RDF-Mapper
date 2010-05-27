module RDFMapper
  module Scope
    
    require 'lib/scope/loader'
    require 'lib/scope/collection'
    require 'lib/scope/query'
    require 'lib/scope/condition'
    
    
    def self.apply(instance, loader, index)
      instance.extend(Model)
      instance.send(:scoped!, loader, index)
    end
    
    ##
    # Extension of RDFMapper::Model that implements lazy-loading. All models
    # in collections and search queries will implement this module by default.
    ##
    module Model
      
      ##
      # Returns instance's unique ID (as RDF::URI).
      ##
      def id
        super || @loader.has_id? || load.id
      end
      
      ##
      # Set data adapter for the query and return self. This will override
      # the default model adapter. It is intended to be used as a chain method:
      #
      #   Person.find(:first).from(:rails)          #=>  #<Person:217132856>
      #   Person.find(:first).from(:rails).name     #=>  'John'
      #
      # @param [Symbol] adapter (:rails, :sparql, :rest)
      # @param [Hash] options options to pass on to the adapter constructor
      #
      # @return [self]
      ##
      def from(adapter, options = {})
        @loader.from(adapter, options)
        self
      end
      
      ##
      # In addition to the original method, preloads the model.
      ##
      def [](name)
        @arbitrary[name] || (@loaded ? super(name) : load[name])
      end
      
      ##
      # In addition to the original method, preloads the model.
      # 
      # @return [Hash] all attributes of an instance (name => value)
      ##
      def properties
        check_for_nil_error
        @loaded ? super : load.properties
      end
      
      ##
      # In addition to the original method, preloads the model.
      # 
      # @return [Hash] all attributes of an instance (name => value)
      ##
      def attributes
        check_for_nil_error
        @loaded ? super : load.attributes
      end
      
      ##
      # Checks if the instance is `nil`. Will load the instance to find it out.
      #
      # @return [Boolean]
      ##
      def nil?
        @nil or (not @loaded and load.nil?)
      end
      
      ##
      # Developer-friendly representation of the instance.
      #
      # @return [String]
      ##
      def inspect #nodoc
        "#<Scoped|%s:%s>" % [self.class, object_id]
      end
      
      
      private
      
      ##
      # Sets Loader instance and object's index in a collection. Called
      # automatically when lazy-loading module is applied.
      ##
      def scoped!(loader, index) #nodoc
        @loader, @index = loader, index
        @loaded, @nil = false, false
        self
      end
      
      ##
      # Flags the instance as `nil`. Returns self.
      ##
      def nil!
        @nil = true
        self
      end
      
      ##
      # In addition to the original method, preloads the model.
      ##
      def get_attribute(name, *args)
        @loaded ? super(name, *args) : load.send(name, *args)
      end
      
      ##
      # Loads the model.
      ##
      def load
        check_for_nil_error
        return self if @loaded
        @loaded = true
        @loader.update(@index, self)
      end
      
      ##
      # Checks if the instance is `nil`. Raises an error if true.
      ##
      def check_for_nil_error
        raise RuntimeError, 'Instance %s is NIL' % self if @nil
      end
      
    end
  end # Scope
end # RDFMapper