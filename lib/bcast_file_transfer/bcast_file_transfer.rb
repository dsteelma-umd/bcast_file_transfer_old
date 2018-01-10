require 'rsync'
require 'json'
require 'fileutils'
require 'logger'
require 'erb'
require 'yaml'

module BcastFileTransfer
  # Library class that holds individual operation steps for use by scripts
  class BcastFileTransfer
    include Logging

    # Determine files that need to be transferred
    def files_to_transfer(destination_server, src_dir) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      dest_server = destination_server['server']
      dest_directory = destination_server['directory']
      dest_username = destination_server['username']

      rsync_options = ['--archive', '--dry-run', '--itemize-changes']

      logger.debug "rsync #{rsync_options.join(' ')} #{src_dir} #{dest_username}@#{dest_server}:#{dest_directory}"

      transfer_files = []
      result = Rsync.run(src_dir, "#{dest_username}@#{dest_server}:#{dest_directory}", rsync_options)
      if result.success?
        result.changes.select { |c| c.file_type == :file && c.update_type == :sent }.each do |change|
          transfer_files << change.filename
        end
      else
        logger.error(
          "Comparison failure: exitcode: #{result.exitcode}, " \
          "error: #{result.error}, " \
          "dest_server: #{dest_server}, " \
          "dest_directory: #{dest_directory}"
        )
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

      logger.error "Error transferring #{filename} to #{dest_server}:#{dest_directory}" unless result.success?

      TransferResult.new(dest_server, dest_directory, src_dir, filename, result)
    end

    # Removes any empty subdirectories in the given directory.
    def prune_empty_subdirectories(dir)
      prune_results = []
      Dir[dir + '**/'].reverse_each do |d|
        next if d == dir # Skip directory itself
        next unless Dir.entries(d).sort == %w[. ..]

        logger.debug "Pruning empty subdirectory: #{d}"
        Dir.rmdir d
        prune_results << PruneResult.new(d)
      end
      prune_results
    end

    # Moves the list of given files from the given src_dir directory to the
    # given transfer directory
    def move_files_after_transfer(files_to_move, src_dir, succesful_transfer_dir)
      move_results = []
      files_to_move.each do |f|
        dest_dir = succesful_transfer_dir + File.dirname(f)
        FileUtils.mkdir_p(dest_dir)
        logger.info "Moving #{f} to #{dest_dir}/#{File.basename(f)}"
        FileUtils.mv "#{src_dir}#{f}", dest_dir
        move_results << MoveResult.new("#{src_dir}#{f}", "#{dest_dir}/#{File.basename(f)}")
      end
      move_results
    end

    # Sends email for the given script_result
    def send_mail(config_hash, script_result)
      Email.send_mail(config_hash, script_result)
    end
  end
end
