# frozen_string_literal: true

# Itly main class
class Itly
  ##
  # Manage list of Plugins
  #
  module Plugins
    private

    # Yield the block with each instanciated plugin
    def run_on_plugins
      raise 'Need a block' unless block_given?

      options.plugins.collect do |plugin|
        yield plugin
      rescue StandardError => e
        logger&.error "Itly Error in #{plugin.class.name}. #{e.class.name}: #{e.message}"
        raise e if options.development?

        nil
      end.compact
    end
  end
end
