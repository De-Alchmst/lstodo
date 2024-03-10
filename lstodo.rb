#! /usr/bin/ruby

require "json"

###########################
# PLATFORM SPECIFIC STUFF #
###########################

IS_WINDOWS = (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil

CONFIG_PATH = IS_WINDOWS \
  ? (ENV["LocalAppData"]) + '\Programs\lstodo\lstodo.json'
  : (ENV["XDG_CONFIG_HOME"] || (ENV["HOME"] + "/.config")) + "/lstodo.json"

# put ./ before path when needed
def make_dir(starting_file)
  if IS_WINDOWS
    unless starting_file =~ /^\w:\\/ # disk letter
      starting_file = ".\\" + starting_file
	end
  else
    unless starting_file =~ /^(\/|\.\/|\.\.\/)/ # / ./ ../
      starting_file = "./" + starting_file
    end
  end

  starting_file
end

def is_text_file?(path)
  if IS_WINDOWS
    # needs to read first few parts of file and test if is utf-8 - encodable
	# not perfect, but will do
	f = File.open(path, "r") \
	  rescue(return false)
	data = f.read(1024) \
	  rescue(return false)
	f.close
	
	data.force_encoding("UTF-8").valid_encoding? \
	  rescue false
  else
    `file -b --mime-encoding "#{path}"` =~ /utf-|ascii/
  end
end

####################
# MANAGE ARGUMENTS #
####################

def help
  abort %{
lstodo: lists any flags in all files in set directory recursively

USAGE: 
  lstodo [flags] [directory]

FLAGS:
  -h, --help      prints this help page
  -r, --reset     resets config file
  -l, --links     sets max number of link jumps
  }.strip
end

starting_file = ""
link_count = 4
reset = false

i = 0
while i < ARGV.length
  # flags #
  if ARGV[i][0] == "-" && ARGV[i].length > 1 && ARGV[i][1] != "-" 
    ARGV[i].chars.drop(1).each { |flag|
      case flag
      when "h"
        help
      when "r"
        reset = true
      when "l"
        i += 1
        link_count = Integer(ARGV[i]) rescue abort("no number given to -l")
      else
        puts "unknown flag: #{flag}"
        help
      end
    }

  elsif ARGV[i].length > 1 && ARGV[i][1] == "-"
    case ARGV[i]
    when "--help"
      help
    when "--reset"
      reset = true
    when "--links"
      i += 1
      link_count = Integer(ARGV[i]) rescue abort("no number given to --links")
    else
      puts "unknown flag: #{ARGV[i]}"
      help
    end

  # starting file #
  else
    if starting_file == ""
      starting_file = ARGV[i]
    else
      puts "wrong argument: #{ARGV[i]}"
      help
    end
  end

  i += 1
end

###############
# LOAD CONFIG #
###############

# generate default one if no found #
unless File.exist? File.dirname(CONFIG_PATH)
Dir.mkdir(File.dirname(CONFIG_PATH)) rescue \
  abort("you don't have permission to create \x1b[1m#{File.dirname(CONFIG_PATH)}\x1b[0m")
end

if (!File.file? CONFIG_PATH) || reset
  conf = File.open(CONFIG_PATH, "w")

  conf.puts JSON.pretty_generate({
    :catch => [
      ["TODO:", "☑️","\x1b[34m"],
      ["NOTE:", "ℹ️","\x1b[36m"],
      ["WARNING:", "⚠️","\x1b[93;1m"],
      ["FIX:", "⛔","\x1b[91;1m"],
      ["FIXME:", "⛔","\x1b[91;1m"],
      ["HACK:", "☣️","\x1b[32;3m"],
    ],

    :ignore => {
      :shell => ["lstodo.rb", "lstodo.json", "node_modules", "bin", "lib"],
      :regex => ["^\\..+"],
    }
  })

  conf.close
end

# load config file #
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

$output = ""

# search file for labels #
def handle_file(path)
  name_written = false

  # skip binary files
  return unless is_text_file? path

  # read file
  f = File.open(path, "r")
  lines = f.readlines
  f.close

  # skip invalid files
  return unless lines.join("").valid_encoding?

  # go through
  lines.length.times { |i|
    for label in $catch do
      if lines[i].match label[0]

        # file header
        if !name_written
          name_written = true
          $output += "\n" + path.sub(Dir.home, "~") + "\n"
        end

        # line #
        line_num = (i+1).to_s

        # styling
        $output += label[2] 
        # symbol
        $output += label[1] + " "*2
        # line number
        $output += line_num + " "*(5-line_num.length)
        # line content
        $output += lines[i].strip
        # remove styling 
        $output += "\x1b[0m\n"
      end
    end
  }
end

# search directory for files #
def search_dir(path, link_count)
  Dir.children(path).each { |item|

    dir = File.join(path, item)
	
    # ignore
    next if item.match($ignore) || !File.readable?(dir)

    # search inner file
    if File.directory? dir
      if File.executable? dir
        # prevent infinite loops
        link_count -= 1 if File.symlink? dir
        next if link_count == 0;

        search_dir(dir, link_count)
      end

    # search contents
    else
      handle_file dir
    end
  }
end

# given file handeling #

# add ./ where needed
starting_file = make_dir starting_file

# give to appropriet function
if File.exist? starting_file
  # file given
  if File.file? starting_file
    handle_file starting_file
  # directory filed
  else
    search_dir starting_file, link_count
  end
else
  abort "file not find: \x1b[1m#{starting_file}\x1b[0m"
end

puts $output.strip unless $output == ""
