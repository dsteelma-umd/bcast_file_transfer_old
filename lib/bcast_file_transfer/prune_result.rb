module BcastFileTransfer
  # Holds the result of a single "prune" operation
  class PruneResult
    attr_reader :dir_name

    def initialize(dir_name)
      @dir_name = dir_name
    end
  end
end
