module RDFMapper
  module Adapters
    ##
    # [-]
    ##
    class SPARQL < Base
      
      ##
      # [-]
      ##
      def initialize(cls, options = {})
        @rdf, @options = cls, options
      end
      
      ##
      # [-]
      ##
      def load(query)
        Query.new(query, @options).find
      end
      
      class Query
        
        include RDFMapper::Logger
        
        ##
        # [-]
        ##
        def initialize(query, options = {})
          @query, @options = query, options
          @rdf = @query.cls
        end
        
        ##
        # [-]
        ##
        def find
          describe
        end
        

        private
        
        ##
        # [-]
        ##
        def describe
          data = sparql_writer(:describe) do |writer|
            triples = @query.to_triples
            writer.write_triples(triples)
            # Target always comes first in first triple
            primary = triples.first.first
            writer.targets << primary
          end
          repository = {}
          download(data).each_triple do |triple|
            s, p, o = triple
            repository[s.to_s] ||= {}
            repository[s.to_s][p.to_s] ||= []  
            repository[s.to_s][p.to_s] << o
          end
          objects(repository)
        end
        
        ##
        # [-]
        ##
        def objects(repository)
          repository.select do |uri, atts|
            atts.key?(RDF.type.to_s)
          end.select do |uri, atts|
            @rdf.type == atts[RDF.type.to_s].first
          end.map do |uri, atts|
            atts.delete(RDF.type.to_s)
            atts[:id] = uri
            atts
          end
        end
        
        ##
        # [-]
        ##
        def sparql_writer(type, &block)
          RDF::Writer.for(:sparql).buffer({ :type => type }, &block)
        end
        
        ##
        # [-]
        ##
        def download(request)
          data = RDFMapper::HTTP.post(@options[:server], request)

          if data =~ /\<sparql/
            RDF::Reader.for(:sparql_results)
          elsif data =~ /\<rdf:RDF/
            RDF::Reader.for(:xml)
          else
            raise RuntimeError, 'Unknown content type'
          end.new(data)
        end
        
      end # Query
    end # SPARQL
  end # Adapters
end # RDFMapper