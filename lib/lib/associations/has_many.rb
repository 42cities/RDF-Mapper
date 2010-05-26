module RDFMapper
  module Associations
    ##
    # [-]
    ##
    class HasMany < Base
      
      ##
      # Replaces the collections content by deleting and adding
      # objects as appropriate.
      ##
      def replace(objects)
        new_objects = filter(objects.to_a)
        return @value if new_objects.empty?
        
        new_objects.each do |child|
          self << child
        end
        
        @value ||= []
        @value.each do |child|
          delete(child) unless new_objects.include?(child)
        end
        
        @value
      end
      
      ##
      # Adds one or more objects to the collection by setting their
      # foreign keys to the collection's primary key.
      ##
      def <<(*objects)
        objects.to_a.select do |child|
          child.kind_of? RDFMapper::Model
        end.each do |child|
          unless include?(child)
            child[reverse] = @instance
            @value << child
          end
        end
        self
      end
      
      alias_method :push, :<<
      
      ##
      # Removes one or more objects from the collection by removing
      # the association between objects
      ##
      def delete(*objects)
        objects.each do |child|
          if include?(child)
            child[reverse] = nil
            @value.delete(child)
          end
        end
        self
      end
      
      ##
      # Removes every object from the collection.
      ##
      def clear
        delete(@value)
      end

      ##
      # Finds an associated object according to the same rules as
      # RDFMapper::Model.find.
      ##
      def find
        raise NotImplementedError, '`find` not yet implemented' # TODO
      end
      
      ##
      # Returns one or more new objects of the collection type that
      # have been instantiated with attributes and linked to this object
      # through a foreign key, but have not yet been saved.
      ##
      def build
        raise NotImplementedError, '`build` not yet implemented' # TODO
      end
      
      ##
      # Returns a new object of the collection type that has been
      # instantiated with attributes, linked to this object through
      # a foreign key, and that has already been saved.
      ##
      def create
        raise NotImplementedError, '`create` not yet implemented' # TODO
      end

      ##
      # Returns true if a given object is present in the collection
      ##
      def include?(object)
        @value ||= []
        @value.include?(object)
      end
            
      ##
      # [-]
      ##
      def to_a
        value
      end
      
      
      private
      
      def filter(objects)
        objects.select do |child|
          child.kind_of? RDFMapper::Model
        end
      end
      
      ##
      # [-]
      ##
      def value
        unless @value.nil?
          return @value
        end
        if @instance.id.nil?
          return []
        end
        replace @association.find(:all, {
          :conditions => { reverse => @instance },
          :skip => [reverse]
        })
      end
      
      ##
      # [-]
      ##
      def reverse
        @reverse ||= @association.has?(nil, @instance)
        if @reverse.nil?
          raise RuntimeError, 'Expected %s to belong to %s' % [@association, @instance.class]
        else
          @reverse.name
        end
      end
      
    end # HasMany
  end # Associations
end # RDFMapper