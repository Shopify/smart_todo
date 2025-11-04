# frozen_string_literal: true

module SmartTodo
  module GitUtils
    class << self
      # Detects if the current directory is a git repository
      # and extracts the GitHub organization and repository name
      # Returns: { org: "Shopify", repo: "smart_todo", url: "https://github.com/Shopify/smart_todo" }
      # Returns nil if not a git repository or cannot parse GitHub URL
      def github_info(base_path = Dir.pwd)
        git_config = File.join(base_path, ".git", "config")
        return unless File.exist?(git_config)

        config_content = File.read(git_config)
        remote_url = parse_remote_url(config_content)
        return unless remote_url

        parse_github_url(remote_url)
      end

      # Generates a GitHub file link with line number
      # e.g., https://github.com/Shopify/smart_todo/blob/main/lib/todo.rb#L42
      def generate_github_link(filepath, line_number, base_path = Dir.pwd)
        github_info = github_info(base_path)
        return unless github_info

        # Convert absolute path to relative path from repo root
        relative_path = if filepath.start_with?(base_path)
          filepath.sub("#{base_path}/", "")
        else
          filepath
        end

        # Get the default branch (typically main)
        branch = default_branch(base_path) || "main"

        "#{github_info[:url]}/blob/#{branch}/#{relative_path}#L#{line_number}"
      end

      private

      # Parses the git config file to extract the remote origin URL
      def parse_remote_url(config_content)
        # Match both HTTPS and SSH formats:
        # - https://github.com/Shopify/smart_todo.git
        # - git@github.com:Shopify/smart_todo.git
        if config_content =~ %r{url\s*=\s*(https://github\.com/[^\s]+|git@github\.com:[^\s]+)}
          ::Regexp.last_match(1)
        end
      end

      # Parses a GitHub URL (HTTPS or SSH) and extracts org/repo info
      def parse_github_url(remote_url)
        case remote_url
        when %r{https://github\.com/([^/]+)/([^/\s]+?)(?:\.git)?$}
          org = ::Regexp.last_match(1)
          repo = ::Regexp.last_match(2)
          {
            org: org,
            repo: repo,
            url: "https://github.com/#{org}/#{repo}",
          }
        when %r{git@github\.com:([^/]+)/([^/\s]+?)(?:\.git)?$}
          org = ::Regexp.last_match(1)
          repo = ::Regexp.last_match(2)
          {
            org: org,
            repo: repo,
            url: "https://github.com/#{org}/#{repo}",
          }
        end
      end

      # Gets the default branch name from HEAD reference
      def default_branch(base_path)
        head_file = File.join(base_path, ".git", "HEAD")
        return unless File.exist?(head_file)

        head_content = File.read(head_file).strip
        if head_content =~ %r{ref: refs/heads/(.+)}
          ::Regexp.last_match(1)
        end
      end
    end
  end
end
