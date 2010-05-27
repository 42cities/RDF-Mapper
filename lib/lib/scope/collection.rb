module RDFMapper
  module Scope
    ##
    # This class contains collections of models. It is primarily used in
    # search queries (find(:all) queries will yield instances of this
    # class) and associations.
    #
    # It implements most commonly used Array and Enumerable methods.
    ##
    class Collection
      
      attr_reader :loader #Temporary
      
      def initialize(cls, options)
        @loader = Loader.new(cls, options)
        @models = []
        @cls = cls
      end
      
      ##
      # Set data adapter for the query and return self. This will override
      # the default model adapter. It is intended to be used as a chain method:
      #
      #   Person.find(:all).from(:rest)          #=>  #<PersonCollection:217132856>
      #   Person.find(:all).from(:rest).length   #=>  10
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
      # Returns first object of the collection. Note that the
      # object is not yet loaded at this point.
      #
      # @return [Object]
      ##
      def first
        at(0)
      end

      ##
      # Returns first object of the collection. Note that the
      # object is not yet loaded at this point.
      #
      # @return [Object]
      ##
      def last
        at(-1)
      end

      ##
      # Returns the object at `index`. Note that the object is
      # not yet loaded at this point.
      #
      # @param [Integer] index
      # @return [Object]
      ##
      def [](index)
        at(index)
      end
      
      ##
      # Returns the object at `index`. Note that the object is
      # not yet loaded at this point.
      #
      # @param [Integer] index
      # @return [Object]
      ##
      def at(index)
        @models[index] ||= @loader.get(index)
      end

      ##
      # Returns true if collection has no objects.
      #
      # @param [Boolean]
      ##
      def empty?
        length == 0
      end

      ##
      # Returns the number of objects in a collection.
      #
      # @return [Integer]
      ##
      def length
        @loader.length
      end

      ##
      # Calls block once for each object in a collection, passing
      # that element as a parameter.
      #
      # @yield [Object]
      # @return [self]
      ##
      def each(&block)
        items.each { |x| block.call(x) }
        self
      end
      
      ##
      # Invokes block once for each object in a collection. Creates
      # a new array containing the values returned by the block
      #
      # @yield [Object]
      # @return [Array]
      ##
      def map(&block)
        items.map { |x| block.call(x) }
      end
      
      ##
      # Returns true if collection contains specified object.
      #
      # @param [Object] object instance of RDFMapper::Model
      # @return [Boolean]
      ##
      def exists?(object)
        items.include?(object)
      end
      
      ##
      # Converts collection into Array.
      #
      # @return [Array]
      ##
      def to_a
        items
      end
      
      alias_method :size, :length
      alias_method :collect, :map
      alias_method :slice, :[]
      alias_method :include?, :exists?

      ##
      # [-]
      ##
      def kind_of?(cls)
        cls == self.class || cls == Enumerable || cls == Array
      end

      ##
      # Developer-friendly representation of the instance
      #
      # @return [String]
      ##
      def inspect #nodoc
        "#<%sCollection:%s>" % [@cls, object_id]
      end


      private
      
      ##
      # Loads entire collection (if needed) and returns all objects.
      ##
      def items #nodoc
        (0..length-1).map { |x| at(x) }
      end

    end # Collection
  end # Scope
end # RDFMapper