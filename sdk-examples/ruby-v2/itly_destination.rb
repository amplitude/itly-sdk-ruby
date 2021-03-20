# frozen_string_literal: true

##
# Collection of options for Itly plugins
#
class ItlyDestination
  ##
  # Options for the Iteratively plugin
  #
  class Iteratively
    ##
    # @param [Integer] buffer_size (optional): Number of event in the buffer before
    #   a flush is triggered. Default: 10
    # @param [Integer] max_retries (optional): Number of retries for pushing
    #   events to the server. Default: 25
    # @param [Float] retry_delay_min: Minimum delay between retries in seconds. Default: 10.0
    # @param [Float] retry_delay_max: Maximum delay between retries in seconds. Default: 3600.0 (1 hour)
    #
    def initialize(buffer_size: 10, max_retries: 25, retry_delay_min: 10.0, retry_delay_max: 3600.0)
      @buffer_size = buffer_size
      @max_retries = max_retries
      @retry_delay_min = retry_delay_min
      @retry_delay_max = retry_delay_max
    end

    def merge(array)
      {
        buffer_size: @buffer_size,
        max_retries: @max_retries,
        retry_delay_min: @retry_delay_min,
        retry_delay_max: @retry_delay_max
      }.merge array
    end
  end

  attr_accessor :iteratively

  ##
  # @params [ItlyDestination::Iteratively] iteratively: Options to pass to the Iteratively plugin
  #
  def initialize(iteratively: ItlyDestination::Iteratively.new)
    @iteratively = iteratively
  end
end
