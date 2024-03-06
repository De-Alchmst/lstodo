#! /usr/bin/ruby

require "json"

###########################
# PLATFORM SPECIFIC STUFF #
###########################

# just unix for now

CONFIG_PATH = (ENV["XDG_CONFIG_HOME"] || (ENV["HOME"] + "/.config")) + "/lstodo.json"

def is_text_file?(path)
  `file -b --mime-encoding "#{path}"` =~ /utf-|ascii/
end

###############
# LOAD CONFIG #
###############

# generate default one if no found
unless File.file? CONFIG_PATH
  conf = File.open(CONFIG_PATH, "w")

  conf.puts JSON.pretty_generate({
    :catch => [
      ["TODO:", "☑️","\x1b[34m"],
      ["NOTE:", "ℹ️","\x1b[36m"],
      ["WARNING:", "⚠️","\x1b[93;1m"],
      ["FIX:", "⛔","\x1b[91;1m"],
      ["HACK:", "☣️","\x1b[32;3m"],
    ],

    :ignore => {
      :shell => ["lstodo.rb", "lstodo.json", "node_modules", "bin"],
      :regex => ["^\\..+"],
    }
  })

  conf.close
end

# load config file
begin
  config = JSON.load_file CONFIG_PATH
  $catch = config["catch"]

  # load regex exceptions
  ignore_str = config["ignore"]["regex"]
  # load shell exceptions and convert to regex
  ignore_str += config["ignore"]["shell"].map { |rx|
    # escape what needs escaping
    rx.gsub! /([\/\[\]\.\^\$\{\}\(\)\+\|])/, "\\\\\\1"
    # shell wildcards
    rx.gsub! /\*/, ".*"
    rx.gsub!  /\?/, "."

    "^#{rx}$"
  }

  $ignore = Regexp.new ignore_str.join "|"

rescue
  abort "Config file \x1b[1m#{CONFIG_PATH}\x1b[0m is not valid." \
      + "Please fix it or remove it."
end

################
# SEARCH FILES #
################

def search_dir(path)
  Dir.children(path).each { |item|

    dir = File.join(path, item)

    # ignore
    next if item.match($ignore) || !File.readable?(dir)

    # search inner file
    if File.directory? dir
      if File.executable? dir
        search_dir dir  
      end

    # search contents
    else
      name_written = false

      # skip binary files
      next unless is_text_file? dir

      # read file
      f = File.open(dir, "r")
      lines = f.readlines
      f.close

      # skip invalid files
      next unless lines.join("").valid_encoding?

      # go through
      lines.length.times { |i|
        for label in $catch do
          if lines[i].match label[0]

            # file header
            if !name_written
              name_written = true
              puts "\n" + dir
            end

            # line #
            line_num = (i+1).to_s

            # styling
            print label[2] 
            # symbol
            print label[1] + " "*2
            # line number
            print line_num + " "*(5-line_num.length)
            # line content
            print lines[i].strip
            # remove styling 
            puts "\x1b[0m"
          end
        end
      }
    end
  }
end

search_dir "."
