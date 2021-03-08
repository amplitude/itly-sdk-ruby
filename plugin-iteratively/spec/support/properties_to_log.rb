# frozen_string_literal: true

module RspecCustomHelpers
  def properties_to_log(hash)
    hash.collect { |k, v| "#{k}: #{v}" }.join ', '
  end
end
