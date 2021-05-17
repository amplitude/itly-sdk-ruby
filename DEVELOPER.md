# Install Ruby
To install different versions of Ruby use `rbenv`
```shell
$ rbenv install 3.0.1
$ rbenv rehash
$ rbenv local 3.0.1
$ ruby --version
```

# Setup
Run `bundle install` in all packages. 
This can be done easily with the `setup` script.
```shell
$ ./bin/setup
```

# Test
Test all
```shell
$ bin/run_all_specs.rb
```

Individual
```shell
$ cd itly-sdk-ruby/sdk
# Add format "documentation" to see descriptive test output
$ LOCAL_ITLY_GEM=1 bin/rspec --format documentation
```

# Code Style
Rubocop is used for linting. Configuration is in `.rubocop.yml`.

[List of available options](https://github.com/rubocop/rubocop/blob/master/config/default.yml) 
```shell
$ rubocop
```