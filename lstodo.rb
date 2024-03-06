#! /usr/bin/ruby

require "json"

###############
# LOAD CONFIG #
###############

CONFIG_PATH = (ENV["XDG_CONFIG_HOME"] || ENV["HOME"]) + "/.config/lstodo.json"

# generate default one if no found
unless File.file? CONFIG_PATH
  conf = File.open(CONFIG_PATH, "w")

  conf.puts JSON.pretty_generate({
    :catch => [
      ["TODO", "ℹ️","\x1b[34m"]
    ],

    :ignore => {
      :shell => [],
      :regex => [],
    }
  })

  conf.close
end

# load config file
begin
  config = JSON.load_file CONFIG_PATH
rescue
  abort "Config file \x1b[1m#{CONFIG_PATH}\x1b[0m is not valid JSON." \
      + "Please fix it or remove it."
end



puts config

puts Dir.foreach(".") {|x| puts x}

Dir.glob("** *").each {|entry| puts entry}
