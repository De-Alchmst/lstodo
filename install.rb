#! /usr/bin/ruby
# test if needs to be installed globaly #
#
require "fileutils"

destination = "#{ENV["HOME"]}/bin/lstodo"

if ARGV.length > 0
  if ARGV[0] == "--global-install"
    destination = "/bin/lstodo-t"
  else
    abort "unknown flag: \x1b[1m#{ARGV[0]}\x1b[0m"
  end
end

unless File.exist? File.dirname(destination)
Dir.mkdir(File.dirname(destination)) rescue \
  abort("you don't have permission to create \x1b[1m#{File.dirname(destination)}\x1b[0m")
end

FileUtils.cp(File.dirname(__FILE__) + "/lstodo.rb", destination) rescue \
  abort("you don't have permission to create \x1b[1m#{destination}\x1b[0m")
