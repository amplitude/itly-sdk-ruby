# frozen_string_literal: true

require 'fileutils'

# Check env variables
raise 'Env variable HOME is empty! Cannot continue' unless ENV['HOME']
raise 'Env variable GEM_HOST_API_KEY is empty! Cannot continue' unless ENV['GEM_HOST_API_KEY']

##
# Configuration
#

# Version under which we will not publish the gems
MIN_VERSION = '1.0.0'

##
# Get requested gems name
#

raise 'Please specify the plugin name.' if ARGV.length != 1

unless %w[amplitude iteratively mixpanel schema-validator segment sdk].include? ARGV[0]
  raise 'The specified plugin name seems incorrect.'
end

plugin_name = ARGV[0]

if plugin_name == 'sdk'
  gem_name = 'itly-sdk'
  gem_path = 'sdk'
else
  gem_name = "itly-plugin-#{plugin_name}"
  gem_path = "plugin-#{plugin_name}"
end

##
# Get data from Rubygem
#

# Get the list of gems from RubyGems
list = `gem list #{gem_name} -ra`

# Search for the requested gem
if list.match(/^(#{Regexp.escape gem_name} \([0-9., ]+\))$/)
  published = true
else
  puts "The gem #{gem_name} is not yet published on RubyGems."
  published = false
end

# Search for the last version number
if published
  line = Regexp.last_match(1)
  raise 'Cannot get the list of published versions' unless line.match(/\((.*)\)/)

  published_version = Regexp.last_match(1).split(',').collect(&:strip).max_by { |v| Gem::Version.new(v) }
end

##
# Get data from source
#

# Read the version file
version_file_path = begin
  case plugin_name
  when 'sdk'
    "#{gem_path}/lib/itly/version.rb"
  when 'schema_validator'
    "#{gem_path}/lib/itly/plugin/schema_validator/version.rb"
  else
    "#{gem_path}/lib/itly/plugin/#{plugin_name}/version.rb"
  end
end

content = File.read version_file_path

# Get the version number
raise "Cannot get the version from source file #{path}" unless content.match(/VERSION\s*=\s*['|"]([\d.]+)['|"]/)

source_version = Gem::Version.new Regexp.last_match(1)

##
# Decide to publish or not
#

# Only publish gems equal or above from version MIN_VERSION
if source_version < Gem::Version.new(MIN_VERSION)
  puts "Source version = #{source_version}. Will not publish gems lower than #{MIN_VERSION}."
  return
end

# Only publish newer version
if published && source_version <= published_version
  puts "Source version = #{source_version}. Published_version = #{published_version}. "\
    'This version is already published.'
  return
end

# Go for publishing
if published
  puts "Source version = #{source_version}. Published_version = #{published_version}. "\
  'Publishing now.'
else
  puts "Source version = #{source_version}. Publishing first version now."
end

##
# Compile and publish
#

# Create RubyGem credential file
credentials_path = "#{ENV['HOME']}/.gem/credentials"

FileUtils.mkdir_p "#{ENV['HOME']}/.gem"
FileUtils.touch credentials_path
FileUtils.chmod 600, credentials_path
File.write credentials_path, "---\n:rubygems_api_key: #{ENV['GEM_HOST_API_KEY']}\n"

# Compile and publish
FileUtils.cd gem_path
puts `gem build #{gem_name}.gemspec`
puts "DRY RUN!! WILL NOT PUBLISH: gem push #{gem_name}-#{source_version}.gem"
# puts `gem push #{gem_name}-#{source_version}.gem`
