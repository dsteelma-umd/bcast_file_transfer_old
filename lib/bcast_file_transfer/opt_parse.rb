require 'optparse'

module BcastFileTransfer
  class OptParse
    def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      options = OpenStruct.new
      options.library = []
      options.inplace = false
      options.encoding = "utf8"
      options.transfer_type = :auto
      options.verbose = false

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: bcast_file_transfer [options]"

        opts.separator ""
        opts.separator "Specific options:"

        # # Mandatory argument.
        # opts.on("-r", "--require LIBRARY",
        #         "Require the LIBRARY before executing your script") do |lib|
        #   options.library << lib
        # end

        # Optional argument; multi-line description.
        opts.on("-c", "--config-file [filepath]",
                "Path to the configuration file") do |config_file|
          options.config_file = config_file
        end


        # Boolean switch.
        # opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        #   options.verbose = v
        # end

        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        # # Another typical switch to print the version.
        # opts.on_tail("--version", "Show version") do
        #   puts ::Version.join('.')
        #   exit
        # end
      end

      opt_parser.parse!(args)
      options
    end  # parse()
  end
end