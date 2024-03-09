#! /usr/bin/ruby
# test if needs to be installed globaly #
#
require "fileutils"

IS_WINDOWS = (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil

destination = IS_WINDOWS ? "#{ENV["LocalAppData"]}\\Programs\\lstodo\\lstodo.rb" : "#{ENV["HOME"]}/bin/lstodo"

if ARGV.length > 0
  if ARGV[0] == "--global-install"
    if IS_WINDOWS
	destination = 'C:\Program Files\lstodo\lstodo.rb'
    else
      destination = "/bin/lstodo-t"
	end
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

# add to path
# slashes made problems in regex, so I replace them
if IS_WINDOWS && !ENV["path"].gsub(/\\/, ">").match(File.dirname(destination).gsub /\\/, ">")
  `setx PATH "%PATH%;#{File.dirname destination}"`
end