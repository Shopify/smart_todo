# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module SmartTodo
  class GitUtilsTest < Minitest::Test
    def test_github_info_with_https_url
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")

        info = GitUtils.github_info(dir)

        assert_equal("Shopify", info[:org])
        assert_equal("smart_todo", info[:repo])
        assert_equal("https://github.com/Shopify/smart_todo", info[:url])
      end
    end

    def test_github_info_with_ssh_url
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "git@github.com:Shopify/smart_todo.git")

        info = GitUtils.github_info(dir)

        assert_equal("Shopify", info[:org])
        assert_equal("smart_todo", info[:repo])
        assert_equal("https://github.com/Shopify/smart_todo", info[:url])
      end
    end

    def test_github_info_with_https_url_without_git_extension
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo")

        info = GitUtils.github_info(dir)

        assert_equal("Shopify", info[:org])
        assert_equal("smart_todo", info[:repo])
        assert_equal("https://github.com/Shopify/smart_todo", info[:url])
      end
    end

    def test_github_info_with_non_github_url
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://gitlab.com/org/repo.git")

        info = GitUtils.github_info(dir)

        assert_nil(info)
      end
    end

    def test_github_info_without_git_repo
      Dir.mktmpdir do |dir|
        info = GitUtils.github_info(dir)

        assert_nil(info)
      end
    end

    def test_generate_github_link_with_valid_repo
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")
        setup_git_branch(dir, "main")

        link = GitUtils.generate_github_link("lib/todo.rb", 42, dir)

        assert_equal("https://github.com/Shopify/smart_todo/blob/main/lib/todo.rb#L42", link)
      end
    end

    def test_generate_github_link_with_absolute_path
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")
        setup_git_branch(dir, "main")

        absolute_path = File.join(dir, "lib/todo.rb")
        link = GitUtils.generate_github_link(absolute_path, 42, dir)

        assert_equal("https://github.com/Shopify/smart_todo/blob/main/lib/todo.rb#L42", link)
      end
    end

    def test_generate_github_link_with_different_branch
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")
        setup_git_branch(dir, "feature-branch")

        link = GitUtils.generate_github_link("lib/todo.rb", 42, dir)

        assert_equal("https://github.com/Shopify/smart_todo/blob/feature-branch/lib/todo.rb#L42", link)
      end
    end

    def test_generate_github_link_without_git_repo
      Dir.mktmpdir do |dir|
        link = GitUtils.generate_github_link("lib/todo.rb", 42, dir)

        assert_nil(link)
      end
    end

    def test_generate_github_link_with_non_github_repo
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://gitlab.com/org/repo.git")
        setup_git_branch(dir, "main")

        link = GitUtils.generate_github_link("lib/todo.rb", 42, dir)

        assert_nil(link)
      end
    end

    def test_find_git_root_from_repo_root
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")

        git_root = GitUtils.find_git_root(dir)

        assert_equal(dir, git_root)
      end
    end

    def test_find_git_root_from_subdirectory
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")
        subdir = File.join(dir, "lib", "smart_todo")
        FileUtils.mkdir_p(subdir)

        git_root = GitUtils.find_git_root(subdir)

        assert_equal(dir, git_root)
      end
    end

    def test_find_git_root_from_file_path
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")
        subdir = File.join(dir, "lib")
        FileUtils.mkdir_p(subdir)
        file_path = File.join(subdir, "todo.rb")
        File.write(file_path, "# test file")

        git_root = GitUtils.find_git_root(file_path)

        assert_equal(dir, git_root)
      end
    end

    def test_find_git_root_without_git_repo
      Dir.mktmpdir do |dir|
        git_root = GitUtils.find_git_root(dir)

        assert_nil(git_root)
      end
    end

    def test_find_git_root_deeply_nested
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")
        deep_dir = File.join(dir, "a", "b", "c", "d", "e")
        FileUtils.mkdir_p(deep_dir)

        git_root = GitUtils.find_git_root(deep_dir)

        assert_equal(dir, git_root)
      end
    end

    def test_find_git_root_caches_results
      Dir.mktmpdir do |dir|
        setup_git_repo(dir, "https://github.com/Shopify/smart_todo.git")
        subdir = File.join(dir, "lib")
        FileUtils.mkdir_p(subdir)

        # First call
        git_root1 = GitUtils.find_git_root(subdir)
        # Second call should hit cache
        git_root2 = GitUtils.find_git_root(subdir)

        assert_equal(dir, git_root1)
        assert_equal(dir, git_root2)
        assert_same(git_root1, git_root2) # Same object reference indicates caching
      end
    end

    private

    def setup_git_repo(dir, remote_url)
      git_dir = File.join(dir, ".git")
      Dir.mkdir(git_dir)

      config_content = <<~CONFIG
        [core]
        	repositoryformatversion = 0
        [remote "origin"]
        	url = #{remote_url}
        	fetch = +refs/heads/*:refs/remotes/origin/*
      CONFIG

      File.write(File.join(git_dir, "config"), config_content)
    end

    def setup_git_branch(dir, branch_name)
      git_dir = File.join(dir, ".git")
      head_content = "ref: refs/heads/#{branch_name}\n"
      File.write(File.join(git_dir, "HEAD"), head_content)
    end
  end
end
