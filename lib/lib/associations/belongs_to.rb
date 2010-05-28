module RDFMapper
  module Associations
    ##
    # [-]
    ##
    class BelongsTo < Base

      ##
      # [-]
      ##
      def id
        value.id
      end
      
      ##
      # [-]
      ##
      def nil?
        value.nil?
      end
      
      ##
      # [-]
      ##
      def kind_of?(type)
        value.kind_of?(type)
      end
      
      ##
      # Replaces current association with a new object
      ##
      def replace(value)
        if value.kind_of? String
          @key = RDF::URI.new(value)
        end
        if value.kind_of? RDF::URI
          @key = value
        end
        if value.kind_of? RDFMapper::Model
          @value = value
        else
          nil
        end
      end

      ##
      # Returns the 'foreign key' (i.e. association URI).
      ##
      def keys
        @key || value.id
      end

      private

      ##
      # [-]
      ##
      def value
        unless @value.nil?
          return @value
        end
        if @key.nil?
          return nil
        end
        replace(@association.find(@key))
      end

    end # BelongsTo
  end # Associations
end # RDFMapper