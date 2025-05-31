# github_analyzer.rb
require 'octokit'
require 'thor'
require 'dotenv/load'

class GitHubAnalyzer < Thor
  desc "repo_stats USER/REPO", "Show stats for a GitHub repository"
  def repo_stats(repo)
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

    puts "Fetching data for #{repo}..."
    begin
      repo_data = client.repo(repo)
      puts "Name: #{repo_data.name}"
      puts "Stars: #{repo_data.stargazers_count}"
      puts "Forks: #{repo_data.forks_count}"
      puts "Open Issues: #{repo_data.open_issues_count}"
      puts "Watchers: #{repo_data.watchers_count}"
    rescue Octokit::NotFound
      puts "Repository not found!"
    end
  end

  desc "user_info USERNAME", "Show public info for a GitHub user"
  def user_info(username)
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

    begin
      user = client.user(username)
      puts "Name: #{user.name}"
      puts "Company: #{user.company}"
      puts "Location: #{user.location}"
      puts "Public Repos: #{user.public_repos}"
      puts "Followers: #{user.followers}"
    rescue Octokit::NotFound
      puts "User not found!"
    end
  end
end

GitHubAnalyzer.start(ARGV)
