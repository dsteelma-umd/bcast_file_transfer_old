module BcastFileTransfer
  # Encapsulates results of running script operations
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
end
