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
      choice = @prompt.select("What would you like to analyze?", %w[Repository User Exit])

      case choice
      when "Repository"
        repo = @prompt.ask("Enter repository (e.g., rails/rails):")
        repo_stats(repo)
      when "User"
        user = @prompt.ask("Enter GitHub username:")
        userChoice = @prompt.select("What Information would you like", %w[Numbers Graphs back])
        case userChoice
        when "Numbers" 
          user_info(user)
        when "Graphs"
          user_activity_plot(user)
        else
          next
        end
        
      else
        puts @pastel.green("Goodbye!")
        break;
      end
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
  end
end