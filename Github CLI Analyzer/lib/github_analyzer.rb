# lib/github_analyzer.rb
require 'octokit'
require 'thor'
require 'dotenv/load'
require 'tty-prompt'
require 'pastel'
require 'unicode_plot'
require 'date'

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
    loop do
      choice = @prompt.select("What would you like to analyze?", ["Repository", "User" ,"API Calls Left","Exit"])

      case choice
      when "Repository"
        repo = search_repositories()
        repoChoice = @prompt.select("What Information would you like?", ["Stats", "Contributors" ,"Languages", "Recent Commits", "Pull Requests","Search Repos","Back"])
        case repoChoice
        when "Stats" 
          repo_stats(repo)
        when "Contributors"
          repo_contributors(repo)
        when "Languages"
          repo_languages(repo)
        when "Recent Commits"
          recent_commits(repo)
        when "Pull Requests"
          repo_pull_requests(repo)
        else
          next
        end
        
      when "User"
        user = @prompt.ask("Enter GitHub username:")
        userChoice = @prompt.select("What Information would you like?", ["Stats", "Graphs" ,"Repositorys","Back"])
        case userChoice
        when "Stats" 
          user_info(user)
        when "Graphs"
          user_activity_plot(user)
        when "Repositorys"
          user_top_repos(user)
        else
          next
        end
      when "API Calls Left"
        rate_limit_check()
      else
        puts @pastel.green("Goodbye!")
        break;
      end
    end
  end

  no_commands do
    #displays repo info
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

    #displays user info
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

    #displays a graph that shows the activitys per day
    def user_activity_plot(username)
      puts @pastel.cyan("📊 Fetching recent activity for #{username}...")

      begin
        events = @client.user_events(username)

        # Count events per day
        activity_by_day = events.group_by { |e| e.created_at.to_date }
                                .transform_values(&:count)
                                .sort.to_h

        if activity_by_day.empty?
          puts @pastel.yellow("No recent public activity.")
          return
        end

        x_numeric = (0...activity_by_day.size).to_a             # [0, 1, 2, ...]
        y_values = activity_by_day.values                       # [5, 3, 10, ...]
        x_labels = activity_by_day.keys.map(&:to_s)             # ["2024-05-20", ...]

        UnicodePlot.lineplot(
          x_numeric,
          y_values,
          title: "📈 GitHub Events per Day (#{username})",
          width: 60,
          height: 15,
          color: :cyan
        ).render

        puts "\n📅 Date Key:"
        x_labels.each_with_index do |label, i|
          puts "  #{i} → #{label}"
        end

      rescue Octokit::NotFound
        puts @pastel.red("User not found.")
      end
    end

    #gets the top 10 contributors from a repo
    def repo_contributors(repo)
      puts @pastel.cyan("👥 Fetching top contributors for #{repo}...")
      begin
        contributors = @client.contributors(repo).first(10)
        contributors.each_with_index do |contributor, i|
          puts "#{i+1}. #{contributor.login} (Commits: #{contributor.contributions})"
        end
      rescue Octokit::NotFound
        puts @pastel.red("Repository not found.")
      end
    end

    #gets the languages from repos and shows the percentages
    def repo_languages(repo)
      puts @pastel.cyan("🧠 Fetching language usage for #{repo}...")
      begin
        langs = @client.languages(repo).to_h
        if langs.empty?
          puts @pastel.yellow("No language data available for this repository.")
          return
        end

        total = langs.values.reduce(0, :+)
        langs.each do |lang, bytes|
          percent = (bytes.to_f / total * 100).round(2)
          puts "#{lang}: #{percent}%"
        end
      rescue Octokit::NotFound
        puts @pastel.red("Repository not found.")
      end
    end

    #displays top repos
    def user_top_repos(username)
      puts @pastel.cyan("🌟 Fetching top repositories by stars for #{username}...")
      begin
        repos = @client.repositories(username)
                    .sort_by { |r| -r.stargazers_count }
                    .first(5)
        repos.each do |repo|
          puts "#{repo.full_name} - ⭐ #{repo.stargazers_count} - 🍴 #{repo.forks_count}"
        end
      rescue Octokit::NotFound
        puts @pastel.red("User not found.")
      end
    end

    #latest commits
    def recent_commits(repo)
      puts @pastel.cyan("📜 Fetching recent commits for #{repo}...")
      commits = @client.commits(repo).first(5)
      commits.each do |commit|
        msg = commit.commit.message.lines.first.strip
        puts "📝 #{msg} by #{commit.commit.author.name} at #{commit.commit.author.date}"
      end
    end

    #lists PRs
    def repo_pull_requests(repo, state = "open")
      puts @pastel.cyan("🔍 Fetching #{state} pull requests for #{repo}...")
      prs = @client.pull_requests(repo, state: state)
      if prs.empty?
        puts @pastel.yellow("No #{state} pull requests found.")
      else
        prs.first(5).each do |pr|
          puts "##{pr.number}: #{pr.title} by #{pr.user.login}"
        end
      end
    end

    #how many api calls left
    def rate_limit_check
      limit = @client.rate_limit
      remaining = limit.remaining
      puts @pastel.magenta("⏳ API calls remaining: #{remaining}/#{limit.limit}")
      puts @pastel.red("⚠️  You are close to the rate limit!") if remaining < 50
    end

    def search_repositories
      query = @prompt.ask("Search for repositories:")
      results = @client.search_repositories(query, per_page: 5)
      repos = results.items.map(&:full_name)
      return @prompt.select("Choose a repo:", repos)

      rescue Octokit::Error => e
        puts @pastel.red("⚠️  Error: #{e.message}")
      
    end


  #end of no_commands do
  end
end