module RDFMapper
  module Scope
    ##
    # Loader is responsible for loading and updating model attributes. An instance
    # of Loader is assigned to each search query and association.
    ##
    class Loader

      def initialize(cls, options = {})
        @conditions = Query.new(cls, options)
        @objects = []
        @cls = cls
      end
      
      ##
      # Checks if model ID is specified within conditions. Returns
      # RDF::URI if found, nil otherwise.
      #
      # @return [RDF::URI]
      # @return [nil]
      ##
      def has_id?
        @conditions[:id].nil? ? nil : RDF::URI.new(@conditions[:id])
      end
      
      ##
      # Sets data adapter or collection.
      #
      # @overload type(adapter, options = {})
      #   Sets data adapter, this will override default model adapter
      #   @param [Symbol] adapter (:rails, :sparql, :rest)
      #   @param [Hash] options options to pass on to the adapter constructor
      #   @return [Object] adapter instance
      #
      # @overload type(collection)
      #   Sets collection of instances that should be queried.
      #   @param [Array] collection
      ##
      def from(adapter_or_collection, options = {})
        if adapter_or_collection.kind_of? Array
          @loaded = true
          adapter_or_collection.select do |instance|
            @conditions.matches?(instance)
          end.each do |instance|
            @objects << instance.properties
          end
          return 
        end
        @adapter = RDFMapper::Adapters.register(adapter_or_collection, @cls, options)
      end

      ##
      # Returns the number of loaded objects.
      #
      # @return [Integer]
      ##
      def length
        load.length
      end
      
      ##
      # Creates a new 'scoped' instance of RDFMapper::Model.
      #
      # @param [Integer] index
      # @return [Object]
      ##
      def get(index)
        instance = @cls.new(@objects[index])
        RDFMapper::Scope.apply(instance, self, index)
      end
      
      ##
      # Updates an existing 'scoped' instance of RDFMapper::Model
      # (sets ID and attributes).
      #
      # @param [Integer] index
      # @param [Object] instance
      # @return [Object]
      ##
      def update(index, instance = nil) #nodoc
        atts = load[index]
        if atts.nil?
          return instance.send(:nil!)
        end
        instance.send(:id=, atts[:id])
        instance.attributes = atts
        instance
      end
      
      ##
      # Developer-friendly representation of the instance
      #
      # @return [String]
      ##
      def inspect #nodoc
        "#<%sLoader:%s>" % [@cls, object_id]
      end

      private

      ##
      # Returns adapter class to be used when loading. It's either the
      # default model adapter or the one explicitly specified via `from`.
      ##
      def adapter #nodoc
        @adapter || @cls.adapter
      end
      
      ##
      # Loads and returns objects. Objects are 'cached' and not reloaded
      # upon subsequent requests.
      ##
      def load #nodoc
        if @loaded
          return @objects
        end
        if adapter.nil?
          raise RuntimeError, "No adapter specified for %s" % @cls
        end
        @loaded = true
        @objects = adapter.load(@conditions)
      end
    
    end # Loader
  end # Scope
end # RDFMapper
