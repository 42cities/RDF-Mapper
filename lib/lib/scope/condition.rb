module RDFMapper
  module Scope
    ##
    # [-]
    ##
    class Condition
      
      attr_reader :eq
      
      def initialize(cls, att, value, eq = '=')
        @cls, @att, @value, @eq = cls, att, value, eq
      end
      
      ##
      # [-]
      ##
      def name
        if @att == :id
          return @att
        end
        if att = @cls.has?(@att)
          att.name
        else
          @att
        end
      end
      
      ##
      # [-]
      ##
      def value(required = [])
        association? ? association(required) : literal
      end
      
      alias_method :check, :value
      
      ##
      # [-]
      ##
      def to_triples(subject)
        to_statements(subject).map do |statement|
          [ statement[:subject], statement[:predicate], statement[:object] ]
        end
      end
      
      ##
      # [-]
      ##
      def to_statements(subject)
        if association?
          object = association.id
          rdf_type = association.to_triples(:short => true)
        else
          object = RDF::Query::Variable.new
          object.bind(value, eq)
          rdf_type = []
        end
        rdf_type + [{
          :subject => subject,
          :predicate => @cls.has?(@att).type,
          :object => object
        }]
      end
      
      ##
      # Developer-friendly representation of the instance.
      #
      # @return [String]
      ##
      def inspect #nodoc
        "#<Condition:(%s%s%s)>" % [name, eq, value]
      end
      
            
      private
      
      ##
      # [-]
      ##
      def association(required = [], value = nil) #nodoc
        if value.nil?
          value = @value
        end
        if value.kind_of? Array or value.kind_of? RDFMapper::Scope::Collection
          return value.map do |item|
            association(required, item)
          end
        end
        unless value.kind_of? RDFMapper::Model
          att = @cls.associations[name]
          value = att.model.find(value.to_s)
        end
        required.each do |att|
          if value[att].nil?
            raise RuntimeError, 'Expected %s to have %s' % [value, att] if value.reload[att].nil?
          end
        end
        value
      end
      
      ##
      # [-]
      ##
      def literal(value = nil) #nodoc
        if value.nil?
          value = @value
        end
        if value.kind_of? Array 
          return value.map do |item|
            literal(item)
          end
        end
        if value.kind_of? RDF::Literal
          value.object
        elsif value.kind_of? RDF::URI
          value.to_s
        else
          value
        end
      end
      
      ##
      # Return the association name that has `name_or_key` as foreign key or name.
      ##
      def association? #nodoc
        att = @cls.associations[name]
        not (att.nil? or att.property?)
      end
      
    end # Condition
  end # Scope
end # RDFMapper