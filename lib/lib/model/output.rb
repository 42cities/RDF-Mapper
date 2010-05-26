module RDFMapper
  class Model

    ##
    # RDF XML representaion of the instance.
    #
    # @todo. Not implemented
    #
    # @param [Hash] options [TODO]
    # @return [String]
    ##
    def to_xml(options = {})
      RDF::Writer.for(:xml).buffer({ :declaration => false }) do |writer|
        if self.class.namespace
          writer.namespace!(self.class.namespace, self.class.ns)
        end
        to_triples.each do |triple|
          writer << triple
        end
      end
    end
    
    ##
    # [-]
    ##
    def to_triples(options = {})
      to_statements(options).map do |statement|
        [ statement[:subject], statement[:predicate], statement[:object] ]
      end
    end
    
    ##
    # options[:short] - class declaration only
    # options[:full] - include associations
    ##
    def to_statements(options = {})
      if options[:full]
        atts = attribute_statements(options)
      elsif options[:short]
        return type_statement
      else
        atts = attribute_statements
      end
      type_statement + atts
    end
    
    private
    
    ##
    # [-]
    ##
    def attribute_statements(options = {})
      @attributes.map do |name, att|
        att.to_statements(options)
      end.flatten.compact
    end
    
    def associations_statements
      
    end
    
    def type_statement
      [{ :subject => id,
         :predicate => RDF.type,
         :object => self.class.type }]
    end
    
  end # Model
end # RDFMapper

