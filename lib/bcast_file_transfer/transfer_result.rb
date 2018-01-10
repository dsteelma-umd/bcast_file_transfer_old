module BcastFileTransfer
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
end
