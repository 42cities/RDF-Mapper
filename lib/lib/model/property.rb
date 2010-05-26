module RDFMapper
  class Model
    class Property

      def initialize(instance, options = {}, *args)
        @instance = instance
        @options = options
        @value = nil
        @new = true
      end

      ##
      # Checks if property has default (nil) value.
      #
      # @params [Boolean]
      ##
      def new?
        @new
      end

      ##
      # Assigns a new value to the property.
      #
      # @param [Object] value
      # @return [Object]
      ##
      def replace(value)
        @new = false
        if value.kind_of? Array
          value = value.first
        end
        if value.kind_of? RDF::Literal
          value = value.object
        end
        @value = case @options[:type]
          when :text      then value.to_s
          when :integer   then value.to_i
          when :float     then value.to_f
          when :uri       then RDF::URI.new(value.to_s)
          else value.to_s
        end
      end

      ##
      # [-]
      ##
      def object(*args)
        @value
      end
      
      ##
      # [-]
      ##
      def to_statements(options = {})
        { :subject => @instance.id,
          :predicate => @options[:type],
          :object => RDF::Literal.new(@value) }
      end

      ##
      # Developer-friendly representation of the instance
      #
      # @return [String]
      ##
      def inspect #nodoc
        @value.inspect
      end

      ##
      # [-]
      ##
      def method_missing(symbol, *args, &block)
        @value.send(symbol, *args, &block)
      end

    end # Property
  end # Model
end # RDFMapper