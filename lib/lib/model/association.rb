module RDFMapper
  class Model
    class << self
      
      ##
      # Specifies a one-to-many association. The following methods for retrieval
      # and query of collections of associated objects will be added:
      #
      # * collection(force_load = false) -- Returns an array of all the associated
      #   objects. An empty array is returned if none are found.
      #
      # * collection<<(object, ...) -- Adds one or more objects to the collection by
      #   setting their foreign keys to the collection‘s primary key.
      #
      # * collection.delete(object, ...) -- Removes one or more objects from the
      #   collection by removing the association between objects.
      #
      # * collection=objects -- Replaces the collections content by deleting and
      #   adding objects as appropriate.
      #
      # * collection.clear -- Removes every object from the collection.
      #
      # * collection.empty? -- Returns true if there are no associated objects.
      #
      # * collection.size -- Returns the number of associated objects.
      #
      # @param [Symbol] name name of the association
      #
      # @param [Symbol] options[:class_name] class name of the association. Use it
      # only if that name can't be inferred from the association name
      #
      # @return [Object] instance of RDFMapper::Attribute
      ##
      def has_many(name, options = {})
        attribute(name, options.merge(:association => :has_many))
      end

      ##
      # Specifies a one-to-one association with another class. The following
      # methods for retrieval and query of the associated object will be added:
      #
      # * association(force_reload = false) -- Returns the associated object.
      #   nil is returned if none is found.
      #
      # * association=(associate) -- Assigns the associate object.
      #
      # @param [Symbol] name name of the association
      #
      # @param [Symbol] options[:class_name] class name of the association. Use it
      # only if that name can't be inferred from the association name
      ##
      def belongs_to(name, options = {})
        attribute(name, options.merge(:association => :belongs_to))
      end
      
    end
  end # Model
end # RDFMapper

