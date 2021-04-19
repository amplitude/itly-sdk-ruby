# frozen_string_literal: true

class FakeCallOptions < Itly::PluginCallOptions
  attr_accessor :data

  def initialize(data:)
    @data = data
  end

  def to_s
    "#<FakeCallOptions: #{data}>"
  end

  def ==(other)
    other.class == self.class && other.data == self.data
  end
end
