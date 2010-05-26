module RDFMapper
  ##
  # Basic HTTP interface, built on top of Patron[http://github.com/toland/patron]
  # library. Used by RDFMapper adapters for communication with external data sources.
  #
  # Patron automatically handles cookies, redirects, timeouts. Can be substituted
  # by any other library as long as HTTP class implements `get` and `post` methods.
  ##
  class HTTP

    require 'patron'

    class << self

      ##
      # Performs a `GET` request and returns received data
      #
      # @param [String, RDF::URI] url
      # @param [Hash] options for Patron constructor
      # @return [String]
      ##
      def get(url, options = {})
        self.new(options).get(url.to_s)
      end

      ##
      # Performs a `POST` request and returns received data
      #
      # @param [String, RDF::URI] url
      # @param [String] data
      # @param [Hash] options for Patron constructor
      # @return [String]
      ##
      def post(url, data, options = {})
        self.new(options).post(url.to_s, data)
      end
    
    end

    ##
    # @return [self]
    ##
    def initialize(options = {})
      @session = Patron::Session.new
      @session.handle_cookies
      @session.timeout = 10
      @session.headers['User-Agent'] = 'Mozilla / RDFMapper'
      @options = options
    end
    
    def get(url)
      @session.get(url, headers).body
    end

    def post(url, data)
      @session.post(url, data, headers).body
    end
    
    private
    
    def headers
      @options[:headers] || {}
    end

  end # HTTP
end # RDFMapper
