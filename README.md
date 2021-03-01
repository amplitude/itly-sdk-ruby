# itly-sdk-ruby

Iteratively SDK for Ruby

# Work locally

If you need to develop or test your plugins locally, you have to use the `LOCAL_ITLY_GEM` environment variable to use the local version of `itly-sdk`.

For example, if you make modifications in the SDK and need to run tests in your plugin:

    cd /workspace/itly-sdk-ruby/my-plugin
    LOCAL_ITLY_GEM=true rspec

In a similar situation, if you need to run the ruby console:

    cd /workspace/itly-sdk-ruby/my-plugin
    LOCAL_ITLY_GEM=true bundle exec bin/console
