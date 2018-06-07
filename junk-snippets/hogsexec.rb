# You must build cpuhogs.so for this
#   cd distem/ext/distem/cpuhogs
#   ruby extconf.rb
#   make

require_relative '../ext/distem/cpuhogs/cpuhogs.so'
require 'optparse'

if Process.euid != 0
  print "Must run as root or with sudo\n"
  exit(1)
end

USAGE="Usage: #{$0} -c cpu1,cpu2... -r ratio or #{$0}"

list_cpu = `more /proc/cpuinfo | grep processor | cut -d' ' -f 2 | paste -s -d","`.strip().split(',')
limitation = {}
core_cli = ""
ratio_cli = false

optparse = OptionParser.new(USAGE) do |opts|
  opts.on("-c N","--cpu N", "List of cpu to limit (comma spearated)") do |str|
    str.split(',').each do |core|
      if !list_cpu.include?(core)
        print("#{core} is not a valid core\n")
        exit(1)
      end
      core_cli = str
    end
  end
  opts.on("-r N", "--ratio N", "ratio in % (eg 10%)") do |str|
    ratio_cli = str.delete('%').to_f/100
  end
end

begin
  optparse.parse!
rescue OptionParser::MissingArgument,OptionParser::InvalidOption => err
  $stderr.puts err
  exit 1
end

if !ratio_cli
    print("Ratio must be specified\n")
    exit(1)
end

if !core_cli.empty?
  core_cli.split(',').each do |core|
    limitation[core.to_i] = ratio_cli.to_f
  end
else
  list_cpu.each do |core|
    limitation[core.to_i] = ratio_cli.to_f
  end
end

print("\nSTARTING HOGS with #{limitation}\n")
print("Press enter to start\n")
STDIN.gets()
ext = CPUExtension::CPUHogs.new
ext.run(limitation)
if ext.running?
  print("HOGS is running\n")
else
  raise "HOGS not running"
end
print("Press enter to stop")
STDIN.gets()
ext.stop()
