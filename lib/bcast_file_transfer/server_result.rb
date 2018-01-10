module BcastFileTransfer
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
end
