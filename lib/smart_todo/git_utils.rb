# frozen_string_literal: true

module SmartTodo
  module GitUtils
    class << self
      # Finds the git repository root by walking up the directory tree from the given path
      # Returns the path to the directory containing .git, or nil if not found
      #
      # @param start_path [String] the starting directory path (usually from a file)
      # @return [String, nil] the git repository root path, or nil if not in a git repo
      def find_git_root(start_path)
        # Normalize to absolute path and use directory if it's a file
        path = File.expand_path(start_path)
        path = File.dirname(path) if File.file?(path)

        # Check cache first
        return git_root_cache[path] if git_root_cache.key?(path)

        # Walk up the directory tree looking for .git
        current_path = path
        loop do
          git_dir = File.join(current_path, ".git")
          if File.exist?(git_dir)
            git_root_cache[path] = current_path
            return current_path
          end

          parent = File.dirname(current_path)
          # Reached filesystem root without finding .git
          if parent == current_path
            git_root_cache[path] = nil
            return
          end

          current_path = parent
        end
      end

      # Detects if the current directory is a git repository
      # and extracts the GitHub organization and repository name
      # Returns: { org: "Shopify", repo: "smart_todo", url: "https://github.com/Shopify/smart_todo" }
      # Returns nil if not a git repository or cannot parse GitHub URL
      #
      # @param base_path [String] the directory path to check (defaults to Dir.pwd)
      # @return [Hash, nil] GitHub info hash or nil
      def github_info(base_path = Dir.pwd)
        # Normalize path
        base_path = File.expand_path(base_path)

        # Check cache first
        return git_info_cache[base_path] if git_info_cache.key?(base_path)

        git_config = File.join(base_path, ".git", "config")
        unless File.exist?(git_config)
          git_info_cache[base_path] = nil
          return
        end

        config_content = File.read(git_config)
        remote_url = parse_remote_url(config_content)
        unless remote_url
          git_info_cache[base_path] = nil
          return
        end

        result = parse_github_url(remote_url)
        git_info_cache[base_path] = result
        result
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

      # Cache accessors - use methods instead of instance variables for thread safety
      def git_root_cache
        @git_root_cache ||= {}
      end

      def git_info_cache
        @git_info_cache ||= {}
      end

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
