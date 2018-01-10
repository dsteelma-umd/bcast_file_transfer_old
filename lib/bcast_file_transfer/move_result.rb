module BcastFileTransfer
  # Holds the result of a single "move" operation
  class MoveResult
    attr_reader :old_location, :new_location

    def initialize(old_location, new_location)
      @old_location = old_location
      @new_location = new_location
    end
  end
end
