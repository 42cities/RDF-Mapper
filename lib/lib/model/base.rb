module RDFMapper
  
  require 'lib/model/association'
  require 'lib/model/output'
  require 'lib/model/attribute'
  require 'lib/model/property'
  
  ##
  # [-]
  ##
  class Model
    
    class << self

      alias_method :original_name, :name #nodoc

      ##
      # Sets or returns model's namespace. It is intended to operate as a shortcut:
      # model and its attributes will calculate their RDF type and predicates
      # automatically. The following two examples produce identical models:
      #
      #   class Person < RDFMapper::Model
      #     namespace 'http://example.org/schema#'
      #     attribute :name
      #     attribute :age
      #   end
      #
      #   class Person < RDFMapper::Model 
      #     type 'http://example.org/schema#Person'
      #     attribute :name, :predicate => 'http://example.org/schema#name'
      #     attribute :age, :predicate => 'http://example.org/schema#age'
      #   end
      #
      #   Person.type  #=> 'http://xmlns.com/foaf/0.1/Person'
      #
      # @overload namespace(value)
      #   Sets model's namespace
      #   @param [RDF::Vocabulary, RDF::URI, String] value
      #
      # @overload namespace
      #   Returns model's namespace
      #   @param [nil]
      #
      # @see type
      # @return [RDF::Vocabulary]
      ##
      def namespace(value = nil, options = {})
        @ns = options[:name] || 'myrdf'
        case value
          when NilClass
            @namespace
          when RDF::Vocabulary
            @namespace = value
          else
            @namespace = RDF::Vocabulary.new(value.to_s)
        end
      end
      
      def ns
        @ns || 'myrdf'
      end
      
      ##
      # Sets or returns model's RDF type
      #
      #   class Company < RDFMapper::Model
      #     type RDF::URI.new('http://example.org/schema#Company')
      #   end
      #
      #   class Person < RDFMapper::Model
      #     type 'http://example.org/schema#Person'
      #   end
      #
      #   Company.type  #=>  #<RDF::URI(http://example.org/schema#Company)>
      #   Person.type   #=>  #<RDF::URI(http://example.org/schema#Person)>
      #
      # @overload type(value)
      #   Sets model's RDF type
      #   @param [RDF::URI, String] value
      #
      # @overload type
      #   @param [nil]
      #
      # @see namespace
      # @return [RDF::URI]
      ##
      def type(value = nil)
        unless value.nil?
          return @type = RDF::URI.new(value.to_s)
        end
        unless @type.nil?
          return @type
        end
        (nil == namespace) == true ? nil : namespace[name]
      end
      
      ##
      # Returns model's name without modules. Original class name is stored
      # as 'original_name'
      #
      #   module TestModule
      #     class Person < RDFMapper::Model; end
      #   end
      #   
      #   Person.name => 'Person'
      #   Person.original_name => 'TestModule::Person'
      #
      # @return [String]
      ##
      def name
        original_name.split('::').last
      end

      ##
      # Sets or returns model's connection adapter.
      # 
      # @overload adapter(instance)
      #   Sets model's connection adapter
      #   @param [Symbol] name adapter name (`:rails`, `:rest` or `:sparql`)
      #   @param [Hash] options options to pass on to the adapter constructor
      #
      # @overload adapter
      #   Returns model's connection adapter
      #
      # @return [Object] an instance of RDFMapper adapter
      ##
      def adapter(name = nil, options = {})
        return @adapter if name.nil?
        @adapter = RDFMapper::Adapters.register(name, self, options)
      end

      ##
      # Returns a model that subclassed {RDFMapper::Model} and has specified
      # URI as its rdf:type
      # 
      #   class Person < RDFMapper::Model
      #     type 'http://example.org/schema#Person'
      #   end
      #
      #   class Company < RDFMapper::Model
      #     namespace 'http://example.org/schema#'
      #   end
      #
      #   RDFMapper::Model['http://example.org/schema#Person']   #=> Person
      #   RDFMapper::Model['http://example.org/schema#Company']  #=> Company
      #   RDFMapper::Model['http://unknown-url.com/']            #=> nil
      #
      # @param [String] URI
      # @param [RDF::URI] URI
      #
      # @return [Object] an RDFMapper model
      ##
      def [](uri)
        return nil if uri.nil?
        @@subclasses.select do |model|
          model.type.to_s == uri.to_s
        end.first
      end

      ##
      # Returns RDFMapper::Attribute that is assigned to the specified name.
      # Accepts symbol, string, RDF::URI as a parameter. Value is optional
      # and is used for associations.
      #
      #   class Person < RDFMapper::Model
      #     namespace 'http://example.org/schema#'
      #     attribute :name, :type => :text
      #     has_many :contacts, :predicate => 'http://example.org/schema#has'
      #     has_many :friends, :predicate => 'http://example.org/schema#has'
      #   end
      #
      #   Person.has?(:name)                                          #=> #<RDFMapper::Model::Attribute>
      #   Person.has?('http://example.org/schema#name')               #=> #<RDFMapper::Model::Attribute>
      #   Person.has?('http://example.org/schema#unknown')            #=> nil
      #
      #   Person.has?('http://example.org/schema#has', Contact)       #=> #<RDFMapper::Model::Attribute>
      #   Person.has?('http://example.org/schema#has', Contact.new)   #=> #<RDFMapper::Model::Attribute>
      #   Person.has?(nil, Contact)                                   #=> #<RDFMapper::Model::Attribute>
      #
      # @param [Symbol, RDF::URI, String] name
      # @param [Object] value
      #
      # @return [RDFMapper::Attribute]
      # @return [nil] if attribute was not found
      ##
      def has?(name, value = nil)
        if name.kind_of? String
          return has?(RDF::URI.new(name), value)
        end
        if name.kind_of? Symbol
          return attributes[name]
        end
        attributes.values.select do |att|
          att.matches?(name, value)
        end.first
      end
      
      ##
      # Returns the association name for the supplied predicate and / or value
      # @see has?
      #
      # @param [Symbol, RDF::URI, String] name
      # @param [Object] value
      #
      # @return [Symbol]
      # @return [nil] if attribute was not found
      ##
      def symbol(name, value = nil)
        att = has?(name, value)
        att.nil? ? nil : att.name
      end
      
      ##
      # Returns a hash of all attributes with their names as keys and
      # RDFMapper::Attribute instances as values.
      #
      # @return [Hash]
      ##
      def attributes
        @attributes ||= {}
      end
            
      ##
      # Returns a hash of all properties with their names as keys and
      # RDFMapper::Attribute instances as values.
      #
      # @return [Hash]
      ##
      def properties
        Hash[attributes.select { |name, att| att.property? }]
      end

      ##
      # Returns a hash of all associations with their names as keys and
      # RDFMapper::Attribute instances as values.
      #
      # @return [Hash]
      ##
      def associations
        Hash[attributes.reject { |name, att| att.property? }]
      end
      
      ##
      # Defines an attribute within a model.
      # 
      # @param [Symbol] name attribute name
      # @param [Symbol] options[:type] attribute type (:text, :uri, :integer, :float)
      # @param [RDF::URI, String] options[:predicate] RDF predicate
      #
      # @return [Object] instance of RDFMapper::Model::Attribute
      ##
      def attribute(name, options = {})
        attributes[name.to_sym] = Attribute.new(self, name.to_sym, options)
        class_eval <<-EOF
          def #{name}(*args, &block)
            get_attribute(:#{name}, *args, &block)
          end
          def #{name}=(value)
            set_attribute(:#{name}, value)
          end
        EOF
      end
      
      ##
      # Creates an object and saves it via the assigned adapter.
      # The resulting object is returned whether the object was saved
      # successfully to the database or not.
      #
      # @param [Hash] attributes attributes of the new object
      # @return [Object] instance of RDFMapper::Model
      # @return [nil] if save was unsuccessful
      ##
      def create(attributes)
        new(attributes).save(attributes[:id])
      end
      
      ##
      # Find operates similarly to Rails' ActiveRecord::Base.find function. It has
      # the same four retrieval approaches:
      # 
      # * Find by id -- This can either be a specific id, a list of ids, or
      #   an array of ids ([5, 6, 10]).
      #
      # * Find first -- This will return the first record matched by the
      #   options used. These options can either be specific conditions or
      #   merely an order. If no record can be matched, `nil` is returned.
      #   Use Model.find(:first, *args) or its shortcut Model.first(*args).
      # 
      # * Find last - This will return the last record matched by the options
      #   used. These options can either be specific conditions or merely an
      #   order. If no record can be matched, `nil` is returned. Use
      #   Model.find(:last, *args) or its shortcut Model.last(*args).
      #
      # * Find all - This will return all the records matched by the options
      #   used. If no records are found, an empty array is returned. Use
      #   Model.find(:all, *args) or its shortcut Model.all(*args).
      ##
      def find(*args)
        options = args.last.is_a?(::Hash) ? args.pop : {}
        case args.first
          when :first   then find_every(options.merge(:limit => 1)).first
          when :last    then find_every(options).last
          when :all     then find_every(options)
          else find_from_ids(args, options)
        end
      end
      
      ##
      # Either finds or creates an object with the specified ID.
      #
      # @param [Hash] attributes attributes of the new object
      # @return [Object] instance of RDFMapper::Model
      # @return [nil] if save was unsuccessful
      ##
      def find_or_create(atts = {})
        instance = atts[:id].nil? ? nil : find(atts[:id])
        instance.nil? ? create(atts) : instance
      end
      
      ##
      # A convenience wrapper for find(:first, *args). You can pass in
      # all the same arguments to this method as you can to find(:first).
      #
      # @see find
      ##
      def first(*args)
        find(:first, *args)
      end

      ##
      # A convenience wrapper for find(:last, *args). You can pass in
      # all the same arguments to this method as you can to find(:last).
      #
      # @see find
      ##
      def last(*args)
        find(:last, *args)
      end

      ##
      # This is an alias for find(:all). You can pass in all the same
      # arguments to this method as you can to find(:all).
      #
      # @see find
      ##
      def all(*args)
        find(:all, *args)
      end
      

      private
      
      ##
      # Returns an Array of instances that match specified conditions.
      # Note that they are not loaded until they are accessed (lazy loading)
      ##
      def find_every(options) #nodoc
        RDFMapper::Scope::Collection.new(self, options)
      end

      ##
      # Returns instances with specified IDs. Depending on the number
      # of IDs it returns either an Array or a single instance (or nil
      # if nothing was found)
      ##
      def find_from_ids(ids, options) #nodoc
        unless ids.kind_of?(Array)
          ids = [ids]
        end
        options[:conditions] ||= { }
        options[:conditions][:id] = ids
        result = find_every(options)
        case ids.size
          when 0 then []
          when 1 then result.first
          else result
        end
      end
            
      ##
      # Keeps track of all models that subclass RDFMapper::Model
      ##
      def inherited(subclass) #nodoc
        @@subclasses ||= []
        @@subclasses << subclass
      end

    end
    
    include RDFMapper::Logger
    
    ##
    # Creates a new instance of a model with specified attributes.
    # Note that attributes include properties as well as associations.
    # It also accepts URIs in addition to symbols:
    #
    #   class Company << RDFMapper::Model
    #     namespace 'http://myschema.com/#'
    #     has_many :people
    #   end
    #   
    #   class Person << RDFMapper::Model
    #     namespace 'http://myschema.com/#'
    #     attribute :name, :type => text
    #     belongs_to :company, :predicate => 'http://myschema.com/#employer'
    #   end
    #
    # The following two examples create identical models:
    #
    #   Person.new(:name => 'John')
    #   Person.new('http://myschema.com/#name' => 'John')
    # 
    # And so do the following two examples:
    #
    #   @company = Company.new(:name => 'MyCo Inc.')
    #
    #   Person.new(:company => @company)
    #   Person.new('http://myschema.com/#employer' => @company)
    #
    # @param [Hash] attributes attributes of the new object
    # @return [Object] instance of RDFMapper::Model
    ##
    def initialize(attributes = {})
      @arbitrary = {}
      @attributes = {}
      @id = nil
      
      self.class.attributes.map do |name, att|
        @attributes[name] = att.value(self)
      end
      
      self.attributes = attributes
      yield self if block_given?
    end
        
    ##
    # Returns objects's unique ID.
    #
    # @return [RDF::URI] object's ID
    ##
    def id(*args)
      @id.nil? ? nil : @id.dup
    end
    
    ##
    # Compares instances based on their IDs.
    #
    # @return [Boolean]
    ##
    def ==(other)
      (other.nil? or other.id.nil?) ? false : (id == other.id)
    end
    
    alias_method :eql?, :==
    alias_method :equal?, :==
    
    ##
    # Returns the value of the attribute identified by `name` after it
    # has been typecast (for example, "2004-12-12"  is cast to a date
    # object, like Date.new(2004, 12, 12)). (Alias for the private
    # get_attribute method).
    #
    # @param [Symbol, String, RDF::URI] name attribute name or predicate URI
    # @return [Object] instance of a property or an association
    ##
    def [](name)
      unless name.kind_of? Symbol
        name = self.class.symbol(name)
      end
      name.nil? ? nil : get_attribute(name)
    end
    
    ##
    # Updates the attribute identified by `name` with the specified
    # value. (Alias for the private set_attribute method).
    # 
    #
    # @param [Symbol, String, RDF::URI] name attribute name or predicate URI
    # @param [Object] value new value of the attribute
    #
    # @return [Object] instance of a property or an association
    ##
    def []=(name, value)
      unless name.kind_of? Symbol
        name = self.class.symbol(name)
      end
      name.nil? ? nil : set_attribute(name, value)
    end
    
    ##
    # Returns a hash of all the properties (i.e. attributes without
    # associations).
    #
    # @return [Hash] all properties of an instance (name => value)
    ##
    def properties(*args)
      Hash[self.class.properties.keys.map do |name|
        [ name, @attributes[name] ]
      end].merge(@arbitrary)
    end
    
    ##
    # Returns a hash of all the attributes with their names as keys and
    # the attributes' values as values.
    # 
    # @return [Hash] all attributes of an instance (name => value)
    ##
    def attributes(*args)
      Hash[@attributes.keys.map do |name|
        [ name, self[name] ]
      end].merge(@arbitrary)
    end
    
    ##
    # Allows you to set all the attributes at once by passing in a hash
    # with keys matching attribute names or RDF predicates.
    #
    # @param [Hash] attributes object's new attributes
    # @return [Hash] hash of all attributes (name => value)
    ##
    def attributes=(hash)
      return unless hash.kind_of? Hash
      hash.nil? ? nil : hash.each { |name, value| self[name] = value }
    end
    
    ##
    # Checks whether the model originated from or was saved to
    # a data source (in other word, whether it has RDF ID).
    #
    # @return [Boolean]
    ##
    def new?
      id.nil?
    end
    
    alias_method :new_record?, :==
    
    ##
    # Saves the instance. If the model is new, a record gets created
    # via the specified adapter (ID must be supplied in this case),
    # otherwise the existing record gets updated.
    #
    # @param [RDF::URI, String] id object's ID
    # @return [Object] self
    # @return [nil] if save was unsuccessful
    ##
    def save(id = nil)
      # Raise error if adapter is unspecified
      check_for_adapter
            
      if new? and id.nil?
        raise RuntimeError, 'Save failed. ID must be specified'
      end
      if new?
        self.id = id
      end
      self.attributes = self.class.adapter.save(self)
      self
    end
    
    ##
    # [-]
    ##
    def reload
      # Raise error if adapter is unspecified
      check_for_adapter

      if id.nil?
        raise RuntimeError, 'Reload failed. Model has no ID'
      end
      
      self.attributes = self.class.adapter.reload(self)
      self
    end
    
    ##
    # Developer-friendly representation of the instance.
    #
    # @return [String]
    ##
    def inspect #nodoc
      "#<%s:%s>" % [self.class, object_id]
    end


    private
    
    ##
    # Raises an error if adapter is undefined.
    ##
    def check_for_adapter #nodoc
      if self.class.adapter.nil?
        raise RuntimeError, 'Save failed. Model adapter is undefined'
      end
    end
    
    ##
    # Sets ID of this object (must be RDF::URI or a String).
    ##
    def id=(value) #nodoc
      @id = RDF::URI.new(value.to_s)
    end
    
    ##
    # Returns the value of an attribute identified by `name` after it
    # has been typecast (for example, "2004-12-12"  is cast to a date
    # object, like Date.new(2004, 12, 12)).
    ##
    def get_attribute(name, *args, &block) #nodoc
      if @attributes.key?(name)
        @attributes[name].object(*args, &block)
      else
        @arbitrary[name]
      end
    end
    
    ##
    # Updates the attribute identified by `name` with the specified value.
    ##
    def set_attribute(name, value) #nodoc
      if name == :id
        return nil
      end
      if @attributes.key?(name)
        @attributes[name].replace(value)
      else
        @arbitrary[name] = value
      end
    end
    
  end # Model
end # RDFMapper

