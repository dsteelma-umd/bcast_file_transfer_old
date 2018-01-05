require 'bcast_file_transfer/version'
require 'rsync'
require 'json'
require 'fileutils'
require 'logger'
require 'erb'
require 'yaml'

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
        if @@logfile.nil? || ("stdout" == @@logfile.strip.downcase)
          logger = Logger.new(STDOUT)
        else
          logger = Logger.new(@@logfile)
        end

        # Note: In Ruby 2.3 and later can use
        # logger.level = onfig_hash['logger.level']
        logger.level = Kernel.const_get @@loglevel
        logger.progname = classname
        logger
      end
    end
  end

  class ScriptResult
    attr_reader :config_hash, :server_results, :move_results, :prune_results
    def initialize(config_hash, server_results, move_results, prune_results)
      @config_hash = config_hash
      @server_results = server_results
      @move_results = move_results
      @prune_results = prune_results
    end

    def success?
      false if @server_results.nil?
      @server_results.map(&:success?).all?
    end
  end

  class ServerResult
    attr_reader :dest_server, :dest_directory, :disable_move_on_failure, :comparison_result, :transfer_results
    def initialize(dest_server, dest_directory, disable_move_on_failure, comparison_result, transfer_results)
      @dest_server = dest_server
      @dest_directory = dest_directory
      @disable_move_on_failure = disable_move_on_failure
      @comparison_result = comparison_result
      @transfer_results = transfer_results
    end

    def success?
      @comparison_result.success? && @transfer_results.map(&:success?).all?
    end
  end

  class ComparisonResult
    attr_reader :dest_server, :dest_directory, :src_dir, :result, :transfer_files

    def initialize(dest_server, dest_directory, src_dir, result, transfer_files)
      @dest_server = dest_server
      @dest_directory = dest_directory
      @src_dir = src_dir
      @result = result
      @transfer_files = transfer_files
    end

    def success?
      @result.success?
    end

    def error
      @result.error
    end
  end

  class TransferResult
    attr_reader :dest_server, :dest_directory, :src_dir, :result, :file

    def initialize(dest_server, dest_directory, src_dir, file, result)
      @dest_server = dest_server
      @dest_directory = dest_directory
      @src_dir = src_dir
      @file = file
      @result = result
    end

    def success?
      @result.success?
    end

    def error
      @result.error
    end
  end

  class MoveResult
    attr_reader :old_location, :new_location

    def initialize(old_location, new_location)
      @old_location = old_location
      @new_location = new_location
    end
  end

  class PruneResult
    attr_reader :dir_name

    def initialize(dir_name)
      @dir_name = dir_name
    end
  end

  class BcastFileTransfer
    include Logging

    # Determine files that need to be transferred
    def files_to_transfer(destination_server, src_dir)
      dest_server = destination_server['server']
      dest_directory = destination_server['directory']
      dest_username = destination_server['username']

      puts "server: #{dest_server}"
      puts "directory: #{dest_directory}"
      puts "src_dir: #{src_dir}"

      rsync_options = ['--archive', '--dry-run', '--itemize-changes']

      logger.debug "rsync #{rsync_options.join(' ')} #{src_dir} #{dest_username}@#{dest_server}:#{dest_directory}"

      transfer_files = []
      result = Rsync.run(src_dir, "#{dest_username}@#{dest_server}:#{dest_directory}", rsync_options)
      if result.success?
        result.changes.each do |change|
          if change.file_type == :file && change.update_type == :sent
            transfer_files << change.filename
          end
        end
      else
        logger.error(
          "Comparison failure: exitcode: #{result.exitcode}, " \
          "error: #{result.error}, " \
          "dest_server: #{dest_server}, " \
          "dest_directory: #{dest_directory}")
      end

      ComparisonResult.new(dest_server, dest_directory, src_dir, result, transfer_files)
    end

    # Copies the given file to the destination server.
    def transfer_file(destination_server, src_dir, filename)
      dest_server = destination_server['server']
      dest_directory = destination_server['directory']
      dest_username = destination_server['username']

      # Append "./" between src_dir and filename. This used by the rsync
      # "relative" functionlity to where the path to starts when transferring
      # the file.
      src_file_path = src_dir + './' + filename

      rsync_options = ['--archive', '--itemize-changes', '--relative']

    #  if rand < 0.1
    #    dest_directory = '/foo/bar'
    #  end
      logger.debug "rsync #{rsync_options.join(' ')} #{src_file_path} #{dest_username}@#{dest_server}:#{dest_directory}"

      result = Rsync.run(src_file_path, "#{dest_username}@#{dest_server}:#{dest_directory}", rsync_options)
      unless result.success?
        logger.error "Error transferring #{filename} to #{dest_server}:#{dest_directory}"
      end
      TransferResult.new(dest_server, dest_directory, src_dir, filename, result)
    end

    def prune_empty_subdirectories(dir)
      prune_results = []
      Dir[dir+'**/'].reverse_each do |d|
        if Dir.entries(d).sort == %w(. ..)
          logger.debug "Pruning empty subdirectory: #{d}"
          Dir.rmdir d
          prune_results << PruneResult.new(d)
        end
      end
      prune_results
    end

    def move_files_after_transfer(files_to_move, src_dir, succesful_transfer_dir)
      move_results = []
      files_to_move.each do |f|
        dest_dir = succesful_transfer_dir+File.dirname(f)
        FileUtils.mkdir_p(dest_dir)
        logger.info "Moving #{f} to #{dest_dir}/#{File.basename(f)}"
        FileUtils.mv "#{src_dir}#{f}", dest_dir
        move_results << MoveResult.new("#{src_dir}#{f}", "#{dest_dir}/#{File.basename(f)}")
      end
      move_results
    end

    def initialize_logger(config_hash)
      logfile = config_hash['logger.logfile']
      if logfile.nil? || ("stdout" == logfile.strip.downcase)
        logger = Logger.new(STDOUT)
      else
        logger = Logger.new(logfile)
      end

      # Note: In Ruby 2.3 and later can use
      # logger.level = onfig_hash['logger.level']
      logger.level = Kernel.const_get config_hash['logger.level']
      logger
    end

    def send_email(script_result)
    #  comparison_results = script_result.comparison_results
    #  transfer_results = script_result.transfer_results

    #  (successful_transfers, failed_transfers) = transfer_results.partition(&:success?)

      email = ""

      if script_result.success?
        email = <<-SUCCESS
          <% (success_servers, failed_servers) = script_result.server_results.partition(&:success?) %>

          <% success_servers.each do |ss| %>
            dest_server: <%= ss.dest_server %>
            dest_directory: <%= ss.dest_directory %>
            <% successful_transfer_count = ss.transfer_results.select(&:success?).count %>
            <% total_transfer_count = ss.transfer_results.count %>

            <%= successful_transfer_count %> of <%= total_transfer_count %> files transferred successfully.

            Files Transferred
            <% ss.transfer_results.each do |t| %>
                <%= t.file %>
            <% end %>
          <% end %>

          <% if script_result.move_results.any? %>
            <%= script_result.move_results.count %> file(s) were moved:
            <% script_result.move_results.each do |m| %>
              <%= m.old_location %> to <%= m.new_location %>
            <% end %>
          <% end %>

          <% if script_result.prune_results.any? %>
            <%= script_result.prune_results.count %> empty directories were pruned:
            <% script_result.prune_results.each do |p| %>
              <%= p.dir_name %>
            <% end %>
          <% end %>

        SUCCESS
      else
        email = <<-FAILURE
          <% (success_servers, failed_servers) = script_result.server_results.partition(&:success?) %>

          Failures occurred!

          Failures
          --------
          <% failed_servers.each do |fs| %>
            dest_server: <%= fs.dest_server %>
            dest_directory: <%= fs.dest_directory %>

            <% unless fs.comparison_result.success? %>
              There were comparison errors:
                  error: <%= fs.comparison_result.result.error %>
                  exitcode: <%= fs.comparison_result.result.exitcode %>
            <% end %>

            <% unless fs.transfer_results.map(&:success?).all? %>
              <% (successful_transfers, failed_transfers) = fs.transfer_results.partition(&:success?) %>
              <% total_transfer_count = fs.transfer_results.count %>

              <%= failed_transfers.count %> of <%= total_transfer_count %> files failed:

              <% failed_transfers.each do |t| %>
                error: <%= t.result.error %>
                exitcode: <%= t.result.exitcode %>
                file: <%= t.file %>
              <% end %>

              <% if successful_transfers.any? %>
                The following <%= successful_transfers.count %> transfers succeeded:
                <% successful_transfers.each do |t| %>
                  file: <%= t.file %>
                <% end %>
              <% end %>
            <% end %>
          <% end %>

          <% if success_servers.any? %>
            Successes
            ---------
            <% success_servers.each do |ss| %>
              dest_server: <%= ss.dest_server %>
              dest_directory: <%= ss.dest_directory %>

              <% successful_transfers = ss.transfer_results.select(&:success?) %>
              <% total_transfer_count = ss.transfer_results.count %>

              <%= successful_transfers.count %> of <%= total_transfer_count %> files transferred successfully.
              <% successful_transfers.each do |t| %>
                file: <%= t.file %>
              <% end %>
            <% end %>
          <% end %>

          <% if script_result.move_results.any? %>
            <%= script_result.move_results.count %> file(s) were moved:
            <% script_result.move_results.each do |m| %>
              <%= m.old_location %> to <%= m.new_location %>
            <% end %>
          <% end %>

          <% if script_result.prune_results.any? %>
            <%= script_result.prune_results.count %> empty directories were pruned:
            <% script_result.prune_results.each do |p| %>
              <%= p.dir_name %>
            <% end %>
          <% end %>
        FAILURE
      end

      email_text = ERB.new(email).result(binding)
      puts "ERB:\n\n #{email_text}"
    end
  end
end
