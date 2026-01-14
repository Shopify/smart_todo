# frozen_string_literal: true

require "pathname"

module SmartTodo
  module DeepLink
    Link = Struct.new(:url, :display, keyword_init: true)

    class << self
      # Filepaths that indicate inline/stdin evaluation and shouldn't be linked
      UNLINKABLE_PATHS = ["-e", "-"].freeze

      # Generate a deep link for a TODO if possible.
      # Returns structured data if a CI environment is detected, nil otherwise.
      #
      # @param todo [SmartTodo::Todo] the todo containing filepath and line numbers
      # @return [Link, nil] Link with url and display, or nil if no link can be generated
      def for_todo(todo)
        return if UNLINKABLE_PATHS.include?(todo.filepath)

        from_github_actions(todo) || from_buildkite(todo)
      end

      private

      def from_github_actions(todo)
        return unless ENV["GITHUB_ACTIONS"]

        prefix = ENV.fetch("SMART_TODO_REPO_PATH") do
          Pathname.new(Dir.pwd).relative_path_from(ENV["GITHUB_WORKSPACE"]).to_s.delete_prefix(".")
        end
        relative_path = join_path(prefix, todo.filepath.delete_prefix("./"))
        repo = "#{ENV["GITHUB_SERVER_URL"]}/#{ENV["GITHUB_REPOSITORY"]}"

        url = if (fragment = line_fragment(todo))
          "#{repo}/blob/#{ENV["GITHUB_SHA"]}/#{relative_path}##{fragment}"
        else
          "#{repo}/blob/#{ENV["GITHUB_SHA"]}/#{relative_path}"
        end

        display = if todo.line_reference
          "#{relative_path}:#{todo.line_reference}"
        else
          relative_path
        end

        Link.new(url: url, display: display)
      end

      def from_buildkite(todo)
        return unless ENV["BUILDKITE"]

        prefix = ENV.fetch("SMART_TODO_REPO_PATH") do
          Pathname.new(Dir.pwd).relative_path_from(ENV["BUILDKITE_BUILD_CHECKOUT_PATH"]).to_s.delete_prefix(".")
        end
        relative_path = join_path(prefix, todo.filepath.delete_prefix("./"))
        repo = ENV["BUILDKITE_REPO"].delete_suffix(".git")

        url = if (fragment = line_fragment(todo))
          "#{repo}/blob/#{ENV["BUILDKITE_COMMIT"]}/#{relative_path}##{fragment}"
        else
          "#{repo}/blob/#{ENV["BUILDKITE_COMMIT"]}/#{relative_path}"
        end

        display = if todo.line_reference
          "#{relative_path}:#{todo.line_reference}"
        else
          relative_path
        end

        Link.new(url: url, display: display)
      end

      def join_path(prefix, path)
        if prefix.empty?
          path
        else
          File.join(prefix, path)
        end
      end

      # GitHub-style line fragment for URL (e.g., "L5" or "L5-L7")
      # Returns nil if line_number is not available
      def line_fragment(todo)
        return unless todo.line_number

        if todo.end_line_number != todo.line_number
          "L#{todo.line_number}-L#{todo.end_line_number}"
        else
          "L#{todo.line_number}"
        end
      end
    end
  end
end
