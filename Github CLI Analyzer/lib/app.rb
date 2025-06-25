require 'sinatra'
require 'puma'
require 'rackup'
require 'json'
require 'socket'
require 'timeout'
require 'octokit'
require 'dotenv/load'

#This is for cntl+c to shutdown the app on windows
Signal.trap("INT") do
  puts "\nGracefully shutting down..."
  exit
end

class GitHubWebApp < Sinatra::Base
  set :public_folder, File.expand_path('../../public', __FILE__)
  set :views, File.expand_path('../../views', __FILE__)

  get '/' do
    erb :index
  end

  get '/api/repos/:username' do
    content_type :json
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

    begin
      repos = client.repositories(params[:username])
      
      repos.map { |r| { 
      name: r.name, 
      description: r.description, 
      url: r.html_url, 
      forks: r.forks_count, 
      OpenIssues: r.open_issues_count, 
      Language: r.language, 
      Stars: r.stargazers_count, 
      Watchers: r.watchers_count 
      } }.to_json
    rescue Octokit::NotFound
      status 404
      { error: "User not found" }.to_json
    end
  end

  get '/api/commits/:username/:repo' do
    content_type :json
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

    begin
      commits = client.commits("#{params[:username]}/#{params[:repo]}")
      commits.map do |c|
        {
          message: c.commit.message,
          author: c.commit.author.name
        }
      end.to_json
    rescue Octokit::NotFound
      status 404
      { error: "Repository not found" }.to_json
    end
  end

  get '/api/profile/:username' do
    content_type :json
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

    begin
      user = client.user(params[:username])
      
      { 
      login: user.login,
      name: user.name,
      avatar_url: user.avatar_url,
      bio: user.bio,
      followers: user.followers,
      following: user.following,
      public_repos: user.public_repos,
      html_url: user.html_url,
      location: user.location,
      blog: user.blog
      } .to_json
    rescue Octokit::NotFound
      status 404
      { error: "User not found" }.to_json
    end
  end

  get '/api/rate_limit' do
  content_type :json

  client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

  begin
    rate_limit = client.rate_limit

    {
      remaining: rate_limit.remaining,
      limit: rate_limit.limit,
      reset_at: rate_limit.resets_at
    }.to_json
  rescue Octokit::Error => e
    status 500
    { error: "Failed to fetch rate limit: #{e.message}" }.to_json
  end
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