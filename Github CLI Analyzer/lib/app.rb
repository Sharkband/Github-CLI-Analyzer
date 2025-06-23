require 'sinatra'
require 'puma'
require 'rackup'
require 'json'
require 'socket'
require 'timeout'

#This is for cntl+c to shutdown the app on windows
Signal.trap("INT") do
  puts "\nGracefully shutting down..."
  exit
end

class GitHubWebApp < Sinatra::Base
  get '/' do
    "Welcome to GitHub Analyzer Web App"
  end

  get '/status' do
    content_type :json
    { status: "running" }.to_json
  end

  # Check if a port is open on the local host (cross-platform-safe)
  def self.port_open?(port, host = 'localhost', timeout_secs = 10)
    Timeout.timeout(timeout_secs) do
        begin
            Socket.tcp(host, port, connect_timeout: timeout_secs) { |sock| sock.close }
            true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError, SystemCallError
            false
        end
    end
  rescue Timeout::Error, Errno::ETIMEDOUT
    puts "⚠️  Timeout while checking port #{port}. Assuming it's in use."
    true
  end

  # Run Sinatra app on a given port, with fallback if the port is in use
  def self.run_with_port_check(port = 4567)
    if port_open?(port)
      puts "❌ Port #{port} is already in use. Please try a different port or stop the existing server."
      exit 1
    else
      puts "✅ Starting GitHub Web App on port #{port}..."
      set :server, 'webrick'
      run! port: port
    end
  end
end

# Start the app when run from CLI, with optional port argument
if __FILE__ == $0
  
  port = (ARGV[0] || 4567).to_i
  GitHubWebApp.run_with_port_check(port)
end