$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), %w{ .. lib})))

require 'fast_db'
require 'tempfile'

def subsql_path
  return $subsql_path  if defined? $subsql_path
  $subsql_path = `which subsql || ([ -x /usr/local/fastdb/bin/subsql ] && echo /usr/local/fastdb/bin/subsql)`.strip
  raise "you have to install fastdb" if $subsql_path.size == 0
  $subsql_path
end

def cleanupsem_path
  subsql_path.gsub('/subsql', '/cleanupsem')
end

def dbname
  return $fastb_spec_dbname  if defined? $fastb_spec_dbname

  $fastb_spec_dbname = "fastdb_spec_db"
end

# TODO: come up with something better
def random_port
  rand(4000) + 1024
end

def setup_database
  return ENV['FAST_DB_PORT'] || 4433
  t = Tempfile.new('fastdb')
  port = random_port
  t.puts "open '#{dbname}'; start server 'localhost:#{port}' 4;"
  t.flush

  stdout = Tempfile.new('stdout')
  stdin, i_dont_need_it_but_dont_want_it_closed = IO.pipe

  $subsql_pid = fork do 
    Thread.list.each do |th| 
      th.kill unless [Thread.main, Thread.current].include?(th)
    end

    Dir.chdir('/tmp')

    STDOUT.reopen stdout
    STDERR.reopen stdout
    STDIN.reopen stdin

    ObjectSpace.each_object(IO) do |io| 
      unless [STDIN, STDOUT, STDERR].include?(io)
        (io.close unless io.closed?) rescue nil 
      end
    end
    
    Process.setpgid(0, Process.pid)

    exec subsql_path, t.path
  end

  # stdin.close
  $kind_of_stdout = stdout
  $kind_of_stdin = stdin

  sleep 0.4

  port
end

def teardown_database
  return
  # puts IO.read($kind_of_stdout.path)
  $kind_of_stdin.puts "quit\n"
  $kind_of_stdin.close
  Process.kill "TERM", $subsql_pid if defined? $subsql_pid
  `#{cleanupsem_path} /tmp/#{dbname} 2>/dev/null > /dev/null`
end

def run_in_thread
  Thread.fork { yield }.join
end
