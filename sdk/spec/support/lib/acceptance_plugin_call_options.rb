# frozen_string_literal: true

class AcceptancePluginCallOptions < Itly::PluginCallOptions
  attr_accessor :specific

  def initialize(specific:)
    @specific = specific
  end

  def to_s
    "#<AcceptancePluginCallOptions: #{specific}>"
  end
end
