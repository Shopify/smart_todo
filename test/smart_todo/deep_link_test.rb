# frozen_string_literal: true

require "test_helper"

module SmartTodo
  class DeepLinkTest < Minitest::Test
    def setup
      super
      @env_backup = ENV.to_h
      # Clear CI env vars so tests start with a clean slate
      ENV.delete("GITHUB_ACTIONS")
      ENV.delete("GITHUB_SERVER_URL")
      ENV.delete("GITHUB_REPOSITORY")
      ENV.delete("GITHUB_SHA")
      ENV.delete("GITHUB_WORKSPACE")
      ENV.delete("BUILDKITE")
      ENV.delete("BUILDKITE_REPO")
      ENV.delete("BUILDKITE_COMMIT")
      ENV.delete("BUILDKITE_BUILD_CHECKOUT_PATH")
      ENV.delete("SMART_TODO_REPO_PATH")
    end

    def teardown
      ENV.replace(@env_backup)
      super
    end

    # Tests for GitHub Actions strategy
    def test_github_actions_strategy
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

        assert_equal("https://github.com/Shopify/smart_todo/blob/abc123/app/models/user.rb#L42", result.url)
        assert_equal("app/models/user.rb:42", result.display)
      end
    end

    def test_github_actions_strategy_with_custom_repo_path
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["SMART_TODO_REPO_PATH"] = "packages/backend"

      result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

      assert_equal(
        "https://github.com/Shopify/smart_todo/blob/abc123/packages/backend/app/models/user.rb#L42",
        result.url,
      )
      assert_equal("packages/backend/app/models/user.rb:42", result.display)
    end

    def test_github_actions_strategy_with_monorepo_subdirectory
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/monorepo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/monorepo/monorepo"

      Dir.stub(:pwd, "/home/runner/work/monorepo/monorepo/packages/backend") do
        result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

        assert_equal(
          "https://github.com/Shopify/monorepo/blob/abc123/packages/backend/app/models/user.rb#L42",
          result.url,
        )
        assert_equal("packages/backend/app/models/user.rb:42", result.display)
      end
    end

    def test_github_actions_strategy_removes_leading_dot_slash
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        result = DeepLink.for_todo(make_todo("./app/models/user.rb", 42))

        assert_equal("https://github.com/Shopify/smart_todo/blob/abc123/app/models/user.rb#L42", result.url)
        assert_equal("app/models/user.rb:42", result.display)
      end
    end

    # Tests for Buildkite strategy
    def test_buildkite_strategy
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://github.com/Shopify/smart_todo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"
      ENV["BUILDKITE_BUILD_CHECKOUT_PATH"] = "/buildkite/builds/agent/smart_todo"

      Dir.stub(:pwd, "/buildkite/builds/agent/smart_todo") do
        result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

        assert_equal("https://github.com/Shopify/smart_todo/blob/def456/app/models/user.rb#L42", result.url)
        assert_equal("app/models/user.rb:42", result.display)
      end
    end

    def test_buildkite_strategy_with_custom_repo_path
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://github.com/Shopify/smart_todo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"
      ENV["SMART_TODO_REPO_PATH"] = "packages/backend"

      result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

      assert_equal(
        "https://github.com/Shopify/smart_todo/blob/def456/packages/backend/app/models/user.rb#L42",
        result.url,
      )
      assert_equal("packages/backend/app/models/user.rb:42", result.display)
    end

    def test_buildkite_strategy_with_monorepo_subdirectory
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://github.com/Shopify/monorepo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"
      ENV["BUILDKITE_BUILD_CHECKOUT_PATH"] = "/buildkite/builds/agent/monorepo"

      Dir.stub(:pwd, "/buildkite/builds/agent/monorepo/packages/backend") do
        result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

        assert_equal(
          "https://github.com/Shopify/monorepo/blob/def456/packages/backend/app/models/user.rb#L42",
          result.url,
        )
        assert_equal("packages/backend/app/models/user.rb:42", result.display)
      end
    end

    def test_buildkite_strategy_removes_leading_dot_slash
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://github.com/Shopify/smart_todo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"
      ENV["BUILDKITE_BUILD_CHECKOUT_PATH"] = "/buildkite/builds/agent/smart_todo"

      Dir.stub(:pwd, "/buildkite/builds/agent/smart_todo") do
        result = DeepLink.for_todo(make_todo("./app/models/user.rb", 42))

        assert_equal("https://github.com/Shopify/smart_todo/blob/def456/app/models/user.rb#L42", result.url)
        assert_equal("app/models/user.rb:42", result.display)
      end
    end

    # Tests for fallback (returns nil when no CI environment)
    def test_returns_nil_when_no_ci_environment
      result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

      assert_nil(result)
    end

    def test_returns_nil_for_eval_path
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"

      result = DeepLink.for_todo(make_todo("-e", 1))

      assert_nil(result)
    end

    def test_returns_nil_for_stdin_path
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"

      result = DeepLink.for_todo(make_todo("-", 1))

      assert_nil(result)
    end

    # Tests for strategy priority
    def test_github_actions_takes_priority_over_buildkite
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://buildkite.example.com/Shopify/smart_todo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

        assert_match(/abc123/, result.url)
        refute_match(/def456/, result.url)
      end
    end

    # Edge cases
    def test_github_enterprise_server_url
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.mycompany.com"
      ENV["GITHUB_REPOSITORY"] = "org/repo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/repo/repo"

      Dir.stub(:pwd, "/home/runner/work/repo/repo") do
        result = DeepLink.for_todo(make_todo("lib/foo.rb", 10))

        assert_equal("https://github.mycompany.com/org/repo/blob/abc123/lib/foo.rb#L10", result.url)
        assert_equal("lib/foo.rb:10", result.display)
      end
    end

    # Tests for line ranges (multi-line TODOs)
    def test_github_actions_with_line_range
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        result = DeepLink.for_todo(make_todo("app/models/user.rb", 42, "line1\nline2\nline3\n"))

        assert_equal(
          "https://github.com/Shopify/smart_todo/blob/abc123/app/models/user.rb#L42-L45",
          result.url,
        )
        assert_equal("app/models/user.rb:42-45", result.display)
      end
    end

    def test_buildkite_with_line_range
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://github.com/Shopify/smart_todo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"
      ENV["BUILDKITE_BUILD_CHECKOUT_PATH"] = "/buildkite/builds/agent/smart_todo"

      Dir.stub(:pwd, "/buildkite/builds/agent/smart_todo") do
        result = DeepLink.for_todo(make_todo(
          "app/models/user.rb",
          10,
          "line1\nline2\nline3\nline4\nline5\n",
        ))

        assert_equal(
          "https://github.com/Shopify/smart_todo/blob/def456/app/models/user.rb#L10-L15",
          result.url,
        )
        assert_equal("app/models/user.rb:10-15", result.display)
      end
    end

    def test_same_start_and_end_line_shows_single_line
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        # No continuation lines, so end_line == start_line
        result = DeepLink.for_todo(make_todo("app/models/user.rb", 42))

        assert_equal(
          "https://github.com/Shopify/smart_todo/blob/abc123/app/models/user.rb#L42",
          result.url,
        )
        assert_equal("app/models/user.rb:42", result.display)
      end
    end

    # Tests for backward compatibility without line_number (deprecated behavior)
    def test_todo_without_line_number_end_line_number_returns_nil
      # Suppress deprecation warning for testing
      assert_output(nil, /deprecated/) do
        todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")
        assert_nil(todo.end_line_number)
      end
    end

    def test_todo_without_line_number_line_reference_returns_nil
      # Suppress deprecation warning for testing
      assert_output(nil, /deprecated/) do
        todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")
        assert_nil(todo.line_reference)
      end
    end

    def test_todo_without_line_number_file_reference_returns_just_filepath
      # Suppress deprecation warning for testing
      assert_output(nil, /deprecated/) do
        todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")
        assert_equal("app/models/user.rb", todo.file_reference)
      end
    end

    def test_todo_without_line_number_github_deep_link_has_no_line_anchor
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        # Suppress deprecation warning for testing
        assert_output(nil, /deprecated/) do
          todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")

          result = DeepLink.for_todo(todo)

          # URL should not have line anchor
          assert_equal("https://github.com/Shopify/smart_todo/blob/abc123/app/models/user.rb", result.url)
          refute_match(/#L\d+/, result.url)
          # Display should not have line reference
          assert_equal("app/models/user.rb", result.display)
        end
      end
    end

    def test_todo_without_line_number_buildkite_deep_link_has_no_line_anchor
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://github.com/Shopify/smart_todo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"
      ENV["BUILDKITE_BUILD_CHECKOUT_PATH"] = "/buildkite/builds/agent/smart_todo"

      Dir.stub(:pwd, "/buildkite/builds/agent/smart_todo") do
        # Suppress deprecation warning for testing
        assert_output(nil, /deprecated/) do
          todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")

          result = DeepLink.for_todo(todo)

          # URL should not have line anchor
          assert_equal("https://github.com/Shopify/smart_todo/blob/def456/app/models/user.rb", result.url)
          refute_match(/#L\d+/, result.url)
          # Display should not have line reference
          assert_equal("app/models/user.rb", result.display)
        end
      end
    end

    def test_todo_without_line_number_github_deep_link_display_text_is_just_filepath
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        # Suppress deprecation warning for testing
        assert_output(nil, /deprecated/) do
          todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")

          result = DeepLink.for_todo(todo)

          # Display text should not contain line reference
          assert_equal("app/models/user.rb", result.display)
          refute_match(/:\d+/, result.display)
        end
      end
    end

    def test_todo_without_line_number_buildkite_deep_link_display_text_is_just_filepath
      ENV["BUILDKITE"] = "true"
      ENV["BUILDKITE_REPO"] = "https://github.com/Shopify/smart_todo.git"
      ENV["BUILDKITE_COMMIT"] = "def456"
      ENV["BUILDKITE_BUILD_CHECKOUT_PATH"] = "/buildkite/builds/agent/smart_todo"

      Dir.stub(:pwd, "/buildkite/builds/agent/smart_todo") do
        # Suppress deprecation warning for testing
        assert_output(nil, /deprecated/) do
          todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")

          result = DeepLink.for_todo(todo)

          # Display text should not contain line reference
          assert_equal("app/models/user.rb", result.display)
          refute_match(/:\d+/, result.display)
        end
      end
    end

    def test_todo_without_line_number_issues_deprecation_warning
      _, err = capture_io do
        Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")
      end

      assert_match(/deprecated/, err)
      assert_match(/line_number:/, err)
      assert_match(/SmartTodo::Todo\.new/, err)
    end

    def test_todo_without_line_number_works_with_monorepo_subdirectory
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/monorepo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/monorepo/monorepo"

      Dir.stub(:pwd, "/home/runner/work/monorepo/monorepo/packages/backend") do
        # Suppress deprecation warning for testing
        assert_output(nil, /deprecated/) do
          todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "app/models/user.rb")

          result = DeepLink.for_todo(todo)

          # Should work but without line anchor
          assert_equal(
            "https://github.com/Shopify/monorepo/blob/abc123/packages/backend/app/models/user.rb",
            result.url,
          )
          assert_equal("packages/backend/app/models/user.rb", result.display)
        end
      end
    end

    def test_todo_without_line_number_removes_leading_dot_slash
      ENV["GITHUB_ACTIONS"] = "true"
      ENV["GITHUB_SERVER_URL"] = "https://github.com"
      ENV["GITHUB_REPOSITORY"] = "Shopify/smart_todo"
      ENV["GITHUB_SHA"] = "abc123"
      ENV["GITHUB_WORKSPACE"] = "/home/runner/work/smart_todo/smart_todo"

      Dir.stub(:pwd, "/home/runner/work/smart_todo/smart_todo") do
        # Suppress deprecation warning for testing
        assert_output(nil, /deprecated/) do
          todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", "./app/models/user.rb")

          result = DeepLink.for_todo(todo)

          # Should remove ./ prefix even without line_number
          assert_equal("https://github.com/Shopify/smart_todo/blob/abc123/app/models/user.rb", result.url)
          assert_equal("app/models/user.rb", result.display)
        end
      end
    end

    private

    def make_todo(filepath, line_number, comment = "")
      todo = Todo.new("# TODO(on: date('2099-01-01'), to: 'test@example.com')", filepath, line_number: line_number)
      comment.each_line { |line| todo << line }
      todo
    end
  end
end
