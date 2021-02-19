# frozen_string_literal: true

# Generate a bunch of FakePlugin classes before a test, and clean up after.
#
# To use: add metadata in the `it` or `describe` block with the number of classes to generate
# Ex: this generates 2 classes, FakePlugin0 and FakePlugin1
#   - describe 'my test', fake_plugins: 2 do ...
#
# Aditionnaly you can list methods you want the fake plugins to answer to
#   by passing an array of symbols to the `:fake_plugins_methods` metadata
# Ex: this makes the fake plugins to answer to #some_method:
#   - describe 'my test', fake_plugins: 2, fake_plugins_methods: [:some_method] do ...

RSpec.configure do |config|
  config.before(:each) do |example|
    if example.metadata[:fake_plugins]
      nbr_plugins = example.metadata[:fake_plugins]
      methods = example.metadata[:fake_plugins_methods] || []

      nbr_plugins.times do |i|
        klass = Class.new(Itly::Plugin) do
          register_plugin self
          methods.each do |method|
            define_method(method) { |*| }
          end
        end
        Object.const_set "FakePlugin#{i}", klass
      end
    end
  end

  config.after(:each) do |example|
    if example.metadata[:fake_plugins]
      nbr_plugins = example.metadata[:fake_plugins]

      nbr_plugins.times do |i|
        Object.send :remove_const, "FakePlugin#{i}"
      end
    end
  end
end
