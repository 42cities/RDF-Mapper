module RDFMapper
  class Model
    ##
    # Contains configuration and convenience methods for model attributes.
    # Instances of this class are assigned to classes (not instances!) of
    # RDFMapper::Model.
    ##
    class Attribute
      
      include RDFMapper::Logger

      attr_reader :name

      ##
      # Constructor is called for each attribute of a model at the time
      # the model is defined.
      # 
      # @param [Object] cls class of the model
      # @param [String] name name of the attribute
      # @param [Hash] options options to pass on to the property / association constructor
      #
      # @return [self]
      ##
      def initialize(cls, name, options)
        @cls = cls
        @name = name
        @options = options.dup
      end
      
      ##
      # Checks if this attribute is a `belongs_to` association.
      #
      # @return [Boolean]
      ##
      def belongs_to?
        not property? and not multiple?
      end

      ##
      # Checks if this attribute is a property (i.e. not an association).
      #
      # @return [Boolean]
      ##
      def property?
        @options[:association].nil?
      end

      ##
      # Returns attribute's RDF predicate.
      #
      # @return [RDF::URI]
      # @return [nil] if not specified and model has no namespace
      ##
      def type
        # Type is 'cached': lookups based on namespace can be quite slow
        @type ||= unless @options[:predicate].nil?
          RDF::URI.new(@options[:predicate].to_s)
        else
          # Keep this weird comparison. RDF::Vocabulary doesn't recognize `nil?` or `==` 
          (nil == @cls.namespace) ? nil : @cls.namespace[@name]
        end
      end
      
      ##
      # Returns class of the associated model. Uses either the `:class_name`
      # option or relies on association name. It follows ActiveRecord naming
      # conventions(e.g. has_many should be plural, belongs_to - singular).
      #
      # @return [Object] a subclass of RDFMapper::Model
      # @return [nil] if association is not found or this is a property attribute
      ##
      def model
        # A bit of 'caching': lookups based on namespace can be quite slow
        unless @model.nil?
          return @model
        end
        
        # Should return nil if this is not an association
        if property?
          return nil
        end

        if @model = model_from_options || model_from_namespace
          @model
        else
          raise RuntimeError, 'Could not find association model for %s (%s :%s)' % [@cls, @options[:association], @name]
        end
      end
      
      ##
      # Returns the class or an instance of a class associated with this
      # attribute.
      
      # When model instance is not specified, it will return Associations::HasMany,
      # Associations::BelongsTo, Property, etc. Alternatively, when RDFMapper::Model
      # is specified, it will return an instance of these classes.
      #
      # @param [Object] instance instance of RDFMapper::Model
      # @return [Object] class of this attribute
      # @return [Object] instance of this attribute 
      ##
      def value(instance = nil)
        if nil == instance
          return attribute_type
        end
        attribute_type.new(instance, @options.merge({
          :cls => model,
          :type => type,
          :name => name
        }))
      end

      ##
      # Checks if this attribute has the same predicate and / or value.
      # Value is accepted both as an instance and a class.
      ##
      def matches?(predicate, value = nil)
        if type.nil?                      # Always false if attribute predicate is not defined
          return false
        end
        if value == nil                   # Checking predicates
          return type.to_s == predicate.to_s
        end
        unless value.respond_to? :new     # Converting instance to a class
          value = value.class
        end
        if model.nil?               # Value is not nil, but model is undefined
          return false
        end
        if value.type != model.type # Value type and model type should match
          return false
        end
        if predicate.nil?                 # Value and model types match
          true
        else
          predicate == type
        end
      end
      
      
      private

      ##
      # Returns attribute's class (e.g. Associations::HasMany, Property) based
      # on the supplied `options[:association]`
      ##
      def attribute_type #nodoc
        case @options[:association]
          when :has_many          then Associations::HasMany
          when :belongs_to        then Associations::BelongsTo
          when :has_one           then Association::HasOne
          when :has_and_belongs   then Association::HasAndBelongs
          else Property
        end
      end

      ##
      # Derives the name of associated model from `options[:class_name]` and
      # returns its class.
      ##
      def model_from_options #nodoc
        @options[:class_name].nil? ? nil : @options[:class_name].constantize
      end

      ##
      # Derives the name of associated model from association name and
      # returns its class
      ##
      def model_from_namespace #nodoc
        name = multiple? ? @name.to_s.classify : @name.to_s.pluralize.classify
        # Keep this weird comparison. RDF::Vocabulary doesn't recognize `nil?` or `==` 
        (nil == @cls.namespace) ? nil : @cls[@cls.namespace[name]]
      end

      ##
      # Checks if this attribute is an association with multiple objects
      # (i.e. `has_many` or `has_and_belongs_to`). Used for deriving association
      # name (plural / singular)
      ##
      def multiple? #nodoc
        @options[:association] == :has_many || @options[:association] == :has_and_belongs
      end
      
    end # Attribute
  end # Model
end # RDFMapper