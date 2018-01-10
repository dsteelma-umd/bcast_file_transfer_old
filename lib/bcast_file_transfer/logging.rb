module BcastFileTransfer
  module Logging
    def logger
      @logger ||= Logging.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    @loggers = {}

    class << self
      def initialize(config_hash)
        @@logfile = config_hash['logger.logfile']
        @@loglevel = config_hash['logger.level']
      end

      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)
        logger = if @@logfile.nil? || 'stdout'.casecmp(@@logfile.strip).zero?
                   Logger.new(STDOUT)
                 else
                   Logger.new(@@logfile)
                 end

        # Note: In Ruby 2.3 and later can use
        # logger.level = onfig_hash['logger.level']
        logger.level = Kernel.const_get @@loglevel
        logger.progname = classname
        logger
      end
    end
  end
end
