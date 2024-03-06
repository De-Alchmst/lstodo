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
      :shell => ["lstodo.rb", "lstodo.json", "[kill.me]? haha / * \\"],
      :regex => ["node_[a-z]*"],
    }
  })

  conf.close
end

# load config file
begin
  config = JSON.load_file CONFIG_PATH
  catch = config["catch"]
  # load regex exceptions
  ignore = config["ignore"]["regex"].map {|rx| Regexp.new "^#{rx}$"}
  # load shell exceptions and convert to regex
  ignore += config["ignore"]["shell"].map {|rx|
    # escape what needs escaping
    rx.gsub! /([\/\\\[\]\.\^\$\{\}\(\)\+\|])/, "\\\\\\1"
    # shell wildcards
    rx.gsub! /\*/, ".*"
    rx.gsub!  /\?/, "."

    Regexp.new "^#{rx}$"
  }

rescue
  abort "Config file \x1b[1m#{CONFIG_PATH}\x1b[0m is not valid." \
      + "Please fix it or remove it."
end


################
# SEARCH FILES #
################

def search_dir(path)
  Dir.children(path).each {|item|
    puts item
  }
end

search_dir Dir.pwd
