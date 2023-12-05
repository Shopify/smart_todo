# frozen_string_literal: true

require "test_helper"

class GitConfigParserTest < Minitest::Test
  def setup
    @test_config_content = <<~HEREDOC
      [remote "origin"]
        url = git@github.com:org_name/repo_name.git
      [user]
        name = John Doe
        email = john@example.com
    HEREDOC
  end

  def test_initialize_parses_git_config_file
    File.stub(:exist?, true) do
      File.stub(:readlines, @test_config_content.lines) do
        assert_equal({
          'remote "origin"' => { 'url' => 'git@github.com:org_name/repo_name.git' },
          'user' => { 'name' => 'John Doe', 'email' => 'john@example.com' }
        }, GitConfigParser.new.instance_variable_get(:@config))
      end
    end
  end

  def test_read_value_returns_value_for_given_section_and_key
    File.stub(:exist?, true) do
      File.stub(:readlines, @test_config_content.lines) do
        assert_equal('git@github.com:org_name/repo_name.git', GitConfigParser.new.read_value('remote "origin"', 'url'))
      end
    end

  end

  def test_read_value_returns_nil_for_nonexistent_section_or_key
     File.stub(:exist?, true) do
      File.stub(:readlines, @test_config_content.lines) do
        assert_nil(GitConfigParser.new.read_value('nonexistent_section', 'nonexistent_key'))
      end
    end
  end

  def test_github_repo_url_returns_correct_github_repository_url
     File.stub(:exist?, true) do
      File.stub(:readlines, @test_config_content.lines) do
        assert_equal('https://github.com/org_name/repo_name/blob/HEAD/', GitConfigParser.new.github_repo_url)
      end
    end
  end
end
