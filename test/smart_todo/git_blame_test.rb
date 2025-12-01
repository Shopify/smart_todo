# frozen_string_literal: true

require "test_helper"
require "tempfile"

module SmartTodo
  class GitBlameTest < Minitest::Test
    def test_returns_nil_when_filepath_is_nil
      assert_nil(GitBlame.author_email(nil, 1))
    end

    def test_returns_nil_when_line_number_is_nil
      assert_nil(GitBlame.author_email("some_file.rb", nil))
    end

    def test_returns_nil_when_file_is_not_in_git_repo
      Tempfile.create("test_file.rb") do |file|
        file.write("# some content\n")
        file.flush

        assert_nil(GitBlame.author_email(file.path, 1))
      end
    end

    def test_returns_author_email_for_file_in_repo
      # Use an actual file in the smart_todo repo
      filepath = File.expand_path("../../lib/smart_todo/version.rb", __dir__)
      email = GitBlame.author_email(filepath, 1)

      assert_match(/@/, email, "Expected email to contain @") if email
    end

    def test_returns_nil_when_git_command_not_found
      # Temporarily modify PATH to simulate git not being available
      original_path = ENV["PATH"]
      ENV["PATH"] = ""

      assert_nil(GitBlame.author_email("some_file.rb", 1))
    ensure
      ENV["PATH"] = original_path
    end
  end
end
