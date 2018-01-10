module BcastFileTransfer
  # Provides globally-accessible logging that allows configuration
  module Logging
    def logger
      @logger ||= Logging.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    @loggers = {}

    class << self
      def initialize(logfile, loglevel)
        @logfile = logfile
        @loglevel = loglevel
      end

      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)
        logger = if @logfile.nil? || 'stdout'.casecmp(@logfile.strip).zero?
                   Logger.new(STDOUT)
                 else
                   Logger.new(@logfile)
                 end

        # Note: In Ruby 2.3 and later can use
        #   logger.level = @loglevel
        # as it will allow a String
        logger.level = Kernel.const_get @loglevel
        logger.progname = classname
        logger
      end
    end
  end
end
