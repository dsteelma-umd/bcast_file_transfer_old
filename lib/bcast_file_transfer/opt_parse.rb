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
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on("--generate-config", "Generates a sample configuration file") do
          if (File.exists?('config.yml'))
            STDERR.puts("ERROR: 'config.yml' file already exists.")
          else
            sample_config_file = File.read(
              File.join(File.dirname(File.expand_path(__FILE__)),
              '../../resources/config/config.yml.sample'))
            File.open('config.yml', 'w') { |file| file.write(sample_config_file) }
            puts ("Created 'config.yml' file. Please update with appropriate values")
          end
          exit
        end

        # Another typical switch to print the version.
        opts.on_tail("--version", "Show version") do
          puts VERSION
          exit
        end
      end

      opt_parser.parse!(args)
      options
    end  # parse()
  end
end