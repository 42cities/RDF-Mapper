module RDFMapper
  module Scope
    ##
    # [-]
    ##
    class Query
      
      include RDFMapper::Logger
      
      attr_reader :cls
      attr_reader :conditions
      attr_reader :sql # Remaining unparsed conditions
      
      def initialize(cls, options = {})
        @options = options
        @conditions = []
        @options[:include] ||= []
        @cls = cls
        @modifier = :and

        case @options[:conditions]
          when Hash   then parse_hash
          when Array  then parse_array
        end
        
      end
      
      ##
      # [-]
      ##
      def modifier
        @modifier.to_s.upcase
      end
      
      ##
      # [-]
      ##
      def strict?
        @modifier == :and
      end
      
      ##
      # [-]
      ##
      def offset
        @options[:offset] || 0
      end
      
      ##
      # [-]
      ##
      def limit
        @options[:limit]
      end
      
      ##
      # [-]
      ##
      def include
        @options[:include]
      end
      
      ##
      # [-]
      ##
      def include!(name)
        @options[:include] << name
      end
      
      ##
      # @todo. Not implemented
      ##
      def order
        nil
      end
      
      ##
      # Checks whether specified object passes all conditions of the query.
      #
      # @param [RDFMapper::Model] object 
      ##
      def matches?(object)
        unless object.kind_of? RDFMapper::Model
          return false
        end
        unless object.class == @cls
          return false
        end
        to_a.reject do |condition|
          condition.matches?(object)
        end.empty?
      end
      
      ##
      # [-]
      ##
      def [](name)
        @conditions.select do |condition|
          condition.name == name
        end.map do |condition|
          condition.value
        end.first
      end
      
      ##
      # Follows the same logic as `to_a` method and returns a Hash instead
      # of an Array (:name => { :eq => value, :value => value }).
      #
      # @see to_a
      #
      # @param [Array<Symbol>] required association attributes that should be preloaded
      # @return [Hash]
      ##
      def to_hash(required = [])
        Hash[to_a(required).map do |name, eq, value|
          [name, { :eq => eq, :value => value }]
        end]
      end
      
      ##
      # Returns an Array of search conditions. Will preload any associated
      # models if their properties are undefined (e.g. in case of REST and
      # SPARQL models are required to have `id` as RDF::URI, and `rails_id`
      # in case of Rails).
      #
      # Note that any foreign-key associations will be renamed. For instance:
      #   :employee_id => #<RDF::URI(http://example.org/people/1354534)>
      # is transformed into
      #   :employee => #<RDFMapper::Model:217132856>
      #
      # @param [Array<Symbol>] required association attributes that should be preloaded
      # @return [Array<Condition>]
      ##
      def to_a(required = [])
        unless required.kind_of? Array
          required = [required]
        end
        @conditions.each do |condition|
          condition.check(required)
        end
      end
      
      ##
      # [-]
      ##
      def to_triples
        to_statements.map do |statement|
          [ statement[:subject], statement[:predicate], statement[:object] ]
        end
      end
      
      ##
      # [-]
      ##
      def to_statements
        target = if self[:id].nil?
          RDF::Query::Variable.new
        else
          RDF::URI.new(self[:id].to_s)
        end
        [{ :subject => target,
           :predicate => RDF.type,
           :object => @cls.type
        }] + to_a(:id).map do |condition|
          condition.to_statements(target)
        end.flatten.compact
      end
      
      ##
      # [-]
      ##
      def flatten(required = [])
        to_a(required).map do |condition|
          (condition.class == self.class) ? condition.flatten(required) : condition
        end.flatten
      end
      
      alias_method :check, :to_a
      
      ##
      # Developer-friendly representation of the instance
      #
      # @return [String]
      ##
      def inspect #nodoc
        "#<Query%s>" % to_a.map do |condition|
          condition.inspect
        end.inspect
      end
      
      
      private

      def add_condition(name, value, eq = '=') #nodoc
        if value.kind_of? Array and value.empty?
          raise RuntimeError, 'No value assigned to `%s`' % name
        end
        @conditions << RDFMapper::Scope::Condition.new(@cls, name, value, eq)
      end

      ##
      # [-]
      ##
      def parse_array #nodoc
        @ary = @options[:conditions][1,255]
        while (read_subquery || read_collection || read_value || read_modifier); end
      end
      
      ##
      # [-]
      ##
      def read_collection #nodoc
        full, name = match(/([^\s]+)[\s]*IN[\s]+\(\?\)[\s]*/)
        return nil if full.nil?
        add_condition(name, @ary.shift)
      end

      ##
      # [-]
      ##
      def read_modifier #nodoc
        full, modifier = match(/[\s]*(AND|OR)/)
        return nil if full.nil?
        @modifier = (modifier == 'OR') ? :or : :and
      end

      ##
      # [-]
      ##
      def read_value #nodoc
        full, name, eq, value, literal, digit = match(/([^\s]+)[\s]*([=><]+)\s*("([\s\w]*)"|([\d\.]+))/)
        return nil if full.nil?
        value = literal.nil? ? digit.to_f : literal.to_s
        add_condition(name, value, eq)
      end

      ##
      # [-]
      ##
      def read_subquery #nodoc
        read_subquery_start || read_subquery_end
      end

      ##
      # [-]
      ##
      def read_subquery_start #nodoc
        return nil if match(/\(/).nil?
        sub = Query.new(@cls, :conditions => [@sql] + @ary)
        @sql = sub.sql[1, sub.sql.length]
        @conditions << sub
      end

      ##
      # [-]
      ##
      def read_subquery_end #nodoc
        return nil if match(/\)/).nil?
        @sql = "|" + @sql
      end
      
      ##
      # Returns a match array
      ##
      def match(pattern)
        if @sql.nil?
          @sql = @options[:conditions].first
        end
        if (@sql =~ pattern) == 0
          @sql = $'.lstrip
          Regexp.last_match.to_a
        end
      end
      
      ##
      # Parses all user-specified `options[:conditions]`
      ##
      def parse_hash #nodoc
        @options[:conditions].map do |att, value|
          parse_hash_item(att, value)
        end.flatten
      end
      
      ##
      # Parses a single `option`
      ##
      def parse_hash_item(att, value) #nodoc
        if value.kind_of? Array
          return value.map do |item|
            parse_hash_item(att, item)
          end
        end
        add_condition(att, value)
      end
      
    end # Query
  end # Scope
end # RDFMapper