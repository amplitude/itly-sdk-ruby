#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'pty'

# Root directory for all gems
root = Pathname.new(File.expand_path(__dir__)).join '..'

# List all directories to run test into
directories = Dir['plugin-*'].sort
directories.unshift 'sdk'

# Run rspec in each dir
directories.each do |dir|
  Dir.chdir root.join(dir)

  cmd = 'LOCAL_ITLY_GEM=true bin/rspec'
  begin
    PTY.spawn(cmd) do |stdout, _stdin, _pid|
      stdout.each { |line| print line }
    rescue Errno::EIO
      # nothing
    end
  rescue PTY::ChildExited
    # nothing
  end
end
