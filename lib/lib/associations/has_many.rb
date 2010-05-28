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
        unless objects.kind_of? Array
          objects = [objects]
        end

        new_objects = filter(objects)
        return self if new_objects.empty?
        
        new_objects.each do |child|
          self << child
        end
        
        @value ||= []
        @value.each do |child|
          delete(child) unless new_objects.include?(child)
        end
        
        self
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
      def find(*args)
        @association.find(*args).from(value)
      end
      
      ##
      # Returns a new object of the collection type that has been
      # instantiated with attributes and linked to this object,
      # but not yet saved.
      ##
      def build(attributes)
        obj = @association.new(attributes)
        (self << obj).last
      end
      
      ##
      # Returns a new object of the collection type that has been
      # instantiated with attributes, linked to this object through
      # a foreign key, and that has already been saved.
      ##
      def create(attributes = {})
        obj = @association.create(attributes.merge({ reverse => @instance }))
        (self << obj).last
      end
      
      ##
      # Either finds or creates a new object in the collection. 
      ##
      def find_or_create(attributes = {})
        obj = attributes[:id].nil? ? nil : find(attributes[:id])
        obj.nil? ? create(attributes) : obj
      end

      ##
      # Returns true if a given object is present in the collection
      ##
      def include?(object)
        value.include?(object)
      end
            
      ##
      # [-]
      ##
      def to_a
        value
      end
      
      ##
      # [-]
      ##
      def kind_of?(cls)
        cls == self.class || cls == Enumerable || cls == Array
      end
      
      ##
      # [-]
      ##
      def from(adapter = nil, options = {})
        if adapter.nil?
          return @adapter
        end
        @adapter = [adapter, options]
        self
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
        @value = []
        replace @association.find(:all, {
          :conditions => { reverse => @instance },
          :skip => [reverse]
        }).from(*self.from)
        @value
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