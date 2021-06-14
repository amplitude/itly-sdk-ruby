# itly-sdk-ruby

Iteratively SDK for Ruby

# Contributions

1. Fork this repository
2. Clone the repository
3. Create a branch
4. Make necessary changes and commit those changes
5. Push changes to GitHub
6. Submit your changes for review

If you need to make changes to one or more plugins and the SDK simultaneously, you need to use the `LOCAL_ITLY_GEM` environment variable to run your tests against your local version of `itly-sdk`.

For example, if you make modifications in the SDK and need to run tests in your plugin:

    cd /workspace/itly-sdk-ruby/my-plugin
    LOCAL_ITLY_GEM=true rspec

In a similar situation, if you need to run the ruby console:

    cd /workspace/itly-sdk-ruby/my-plugin
    LOCAL_ITLY_GEM=true bundle exec bin/console

# Strong typing

This project is using ruby RBS to define typing signature. For every change you make, you will need to maintain the signature files. See the official repository for more information. Here are some pointers.

To generate the prototype of a new classes:

    cd /workspace/itly-sdk-ruby/my-plugin
    bundle exec rbs prototype rb path/to/my_class.rb > sig/my_class.rbs

The generated prototype will mainly be untyped, so you will need to define all the types precisely. Then you can validate the syntax of your signature files with the following:

    cd /workspace/itly-sdk-ruby/my-plugin
    bundle exec steep validate

# Testing

To run RSpec in the SDK of in the plugin:

    cd /workspace/itly-sdk-ruby/sdk
    bin/rspec

To run rspec in all gems:

    cd /workspace/itly-sdk-ruby/
    bin/run_all_specs.rb
