# lib/github_analyzer.rb
require 'octokit'
require 'thor'
require 'dotenv/load'
require 'tty-prompt'
require 'pastel'

class GitHubAnalyzer < Thor
  
  def initialize(*args)
    super
    @client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    @prompt = TTY::Prompt.new
    @pastel = Pastel.new
  end

  desc "analyze", "Start interactive GitHub analysis"
  def analyze
    puts "Starting CLI..."
    choice = @prompt.select("What would you like to analyze?", %w[Repository User Exit])

    case choice
    when "Repository"
      repo = @prompt.ask("Enter repository (e.g., rails/rails):")
      repo_stats(repo)
    when "User"
      user = @prompt.ask("Enter GitHub username:")
      user_info(user)
    else
      puts @pastel.green("Goodbye!")
    end
  end

  no_commands do
    def repo_stats(repo)
      puts @pastel.cyan("Fetching repo data for #{repo}...")
      begin
        data = @client.repo(repo)
        puts @pastel.bold("Name: ") + data.name
        puts @pastel.yellow("⭐ Stars: #{data.stargazers_count}")
        puts @pastel.green("🍴 Forks: #{data.forks_count}")
        puts @pastel.red("🐞 Issues: #{data.open_issues_count}")
        puts @pastel.blue("👁 Watchers: #{data.watchers_count}")
      rescue Octokit::NotFound
        puts @pastel.red("Repository not found.")
      end
    end

    def user_info(username)
      puts @pastel.cyan("Fetching user data for #{username}...")
      begin
        user = @client.user(username)
        puts @pastel.bold("Name: ") + (user.name || "N/A")
        puts @pastel.yellow("🏢 Company: #{user.company || 'N/A'}")
        puts @pastel.blue("📍 Location: #{user.location || 'N/A'}")
        puts @pastel.green("📦 Repos: #{user.public_repos}")
        puts @pastel.magenta("👥 Followers: #{user.followers}")
      rescue Octokit::NotFound
        puts @pastel.red("User not found.")
      end
    end
  end
end