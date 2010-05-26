module RDFMapper
  module Associations
    
    autoload :BelongsTo,      'lib/associations/belongs_to'
    autoload :HasMany,        'lib/associations/has_many'
    autoload :HasOne,         'lib/associations/has_one'
    autoload :HasAndBelongs,  'lib/associations/has_and_belongs'

    ##
    # Base class for all association types. Contains default constructor.
    ##
    class Base
      
      include RDFMapper::Logger
      
      def initialize(instance, options = {})
        @instance = instance
        @association = options[:cls]
        @options = options
      end
      
      ##
      # [-]
      ##
      def replace(value)
        raise NotImplementedError, 'Expected association to override `replace`'
      end
      
      ##
      # [-]
      ##
      def object(force = false)
        value.nil? and value.empty? if force
        self
      end
      
      ##
      # [-]
      ##
      def to_statements(options = {})
        options[:skip] ||= []
        if value.kind_of? Array
          items = value
        else
          items = [value]
        end
        items.reject do |item|
          options[:skip].include?(items)
        end.map do |item|
          node = if options[:full]
            item.to_statements(:skip => @instance)
          else
            item.to_statements(:short => true)
          end
          node + [{
            :subject => @instance.id,
            :predicate => @options[:type],
            :object => item.id
          }]
        end.flatten
      end
      
      ##
      # Developer-friendly representation of the instance
      #
      # @return [String]
      ##
      def inspect #nodoc
        value.inspect
      end
      
      
      private

      ##
      # [-]
      ##
      def value
        raise NotImplementedError, 'Expected association to override `value`'
      end
      
      ##
      # [-]
      ##
      def method_missing(symbol, *args, &block)
        if value.respond_to? symbol
          value.send(symbol, *args, &block)
        else
          raise RuntimeError, 'Undefined method `%s`' % symbol
        end
      end
      
    end # Base
  end # Associations
end # RDFMapper