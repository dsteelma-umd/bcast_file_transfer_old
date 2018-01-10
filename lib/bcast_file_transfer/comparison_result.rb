module BcastFileTransfer
  # Encapsulates the comparision results for a single destination server
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
end
