module RDFMapper
  ##
  # A convenience wrapper around Ruby's standard Logger object.
  ##
  module Logger
    module Configuration
      class << self

        def to(target, level = 4, name = nil)
          io = case target
            when :stdout then $stdout
            when :file then File.open(name, 'a+')
            else String
          end
          @target = ::Logger.new(io)
        end
      
        def target
          @target || to(:stdout)
        end
        
      end
    end
    
    ##
    # Logs a fatal error using RDFMapper::Logger
    #
    # @return[true]
    ##
    def fatal(message)
      log(4, message)
    end
    
    ##
    # Logs a warning message using RDFMapper::Logger
    #
    # @return[true]
    ##
    def warn(message)
      log(2, message)
    end
    
    ##
    # Logs a debug message using RDFMapper::Logger
    #
    # @return[true]
    ##
    def debug(message)
      log(0, message)
    end
    
    private
    
    ##
    # Logs a message using RDFMapper::Logger
    #
    # @param [Integer] severity from 0 to 5 (see Logger::Severity)
    # @param [String] message
    # @return[true] 
    ##
    def log(severity, message)
      timestamp = Time.now.strftime('%m-%d %H:%M:%S')
      formatted = "[%s] %s | %s" % [timestamp, self.class.name, message]
      RDFMapper::Logger::Configuration.target.add(severity, formatted)
    end
    
  end
end