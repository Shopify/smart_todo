# frozen_string_literal: true

gem("bundler")
require "bundler"
require "net/http"
require "time"
require "json"

module SmartTodo
  # This module contains all the methods accessible for SmartTodo comments.
  # It is meant to be reopened by the host application in order to define
  # its own events.
  #
  # An event needs to return a +String+ containing the message that will be
  # sent to the TODO assignee or +false+ in case the event hasn't been met.
  #
  # @example Adding a custom event
  #   module SmartTodo
  #     class Events
  #       def trello_card_close(card)
  #         ...
  #       end
  #     end
  #   end
  #
  #   TODO(on: trello_card_close(381), to: 'john@example.com')
  #
  class Events
    def initialize(now: nil, spec_set: nil, current_ruby_version: nil)
      @now = now
      @spec_set = spec_set
      @rubygems_client = nil
      @github_client = nil
      @current_ruby_version = current_ruby_version
    end

    # Check if the +date+ is in the past
    #
    # @param on_date [String] a string parsable by Time.parse
    # @return [false, String]
    def date(on_date)
      if now >= Time.parse(on_date)
        "We are past the *#{on_date}* due date and " \
          "your TODO is now ready to be addressed."
      else
        false
      end
    end

    # Check if a new version of +gem_name+ was released with the +requirements+ expected
    #
    # @example Expecting a specific version
    #   gem_release('rails', '6.0')
    #
    # @example Expecting a version in the 5.x.x series
    #   gem_release('rails', '> 5.2', '< 6')
    #
    # @param gem_name [String]
    # @param requirements [Array<String>] a list of version specifiers
    # @return [false, String]
    def gem_release(gem_name, *requirements)
      response = rubygems_client.get("/api/v1/versions/#{gem_name}.json")

      if response.code_type < Net::HTTPClientError
        "The gem *#{gem_name}* doesn't seem to exist, I can't determine if " \
          "your TODO is ready to be addressed."
      else
        requirement = Gem::Requirement.new(requirements)
        version = JSON.parse(response.body).find { |gem| requirement.satisfied_by?(Gem::Version.new(gem["number"])) }

        if version
          "The gem *#{gem_name}* was released to version *#{version["number"]}* and " \
            "your TODO is now ready to be addressed."
        else
          false
        end
      end
    end

    # Check if +gem_name+ was bumped to the +requirements+ expected
    #
    # @example Expecting a specific version
    #   gem_bump('rails', '6.0')
    #
    # @example Expecting a version in the 5.x.x series
    #   gem_bump('rails', '> 5.2', '< 6')
    #
    # @param gem_name [String]
    # @param requirements [Array<String>] a list of version specifiers
    # @return [false, String]
    def gem_bump(gem_name, *requirements)
      specs = spec_set[gem_name]

      if specs.empty?
        "The gem *#{gem_name}* is not in your dependencies, I can't determine if " \
          "your TODO is ready to be addressed."
      else
        requirement = Gem::Requirement.new(requirements)
        version = specs.first.version

        if requirement.satisfied_by?(version)
          "The gem *#{gem_name}* was updated to version *#{version}* and " \
            "your TODO is now ready to be addressed."
        else
          false
        end
      end
    end

    # Check if the issue +issue_number+ is closed
    #
    # @param organization [String] the GitHub organization name
    # @param repo [String] the GitHub repo name
    # @param issue_number [String, Integer]
    # @return [false, String]
    def issue_close(organization, repo, issue_number)
      headers = github_headers(organization, repo)
      response = github_client.get("/repos/#{organization}/#{repo}/issues/#{issue_number}", headers)

      if response.code_type < Net::HTTPClientError
        <<~EOM
          I can't retrieve the information from the issue *#{issue_number}* in the *#{organization}/#{repo}* repository.

          If the repository is a private one, make sure to export the `#{GITHUB_TOKEN}`
          environment variable with a correct GitHub token.
        EOM
      elsif JSON.parse(response.body)["state"] == "closed"
        "The issue https://github.com/#{organization}/#{repo}/issues/#{issue_number} is now closed, " \
          "your TODO is ready to be addressed."
      else
        false
      end
    end

    # Check if the pull request +pr_number+ is closed
    #
    # @param organization [String] the GitHub organization name
    # @param repo [String] the GitHub repo name
    # @param pr_number [String, Integer]
    # @return [false, String]
    def pull_request_close(organization, repo, pr_number)
      headers = github_headers(organization, repo)
      response = github_client.get("/repos/#{organization}/#{repo}/pulls/#{pr_number}", headers)

      if response.code_type < Net::HTTPClientError
        <<~EOM
          I can't retrieve the information from the PR *#{pr_number}* in the *#{organization}/#{repo}* repository.

          If the repository is a private one, make sure to export the `#{GITHUB_TOKEN}`
          environment variable with a correct GitHub token.
        EOM
      elsif JSON.parse(response.body)["state"] == "closed"
        "The pull request https://github.com/#{organization}/#{repo}/pull/#{pr_number} is now closed, " \
          "your TODO is ready to be addressed."
      else
        false
      end
    end

    # Retrieve context information for an issue
    # This is used when a TODO has a context: issue() attribute
    #
    # @param organization [String] the GitHub organization name
    # @param repo [String] the GitHub repo name
    # @param issue_number [String, Integer]
    # @return [String, nil]
    def issue_context(organization, repo, issue_number)
      headers = github_headers(organization, repo)
      response = github_client.get("/repos/#{organization}/#{repo}/issues/#{issue_number}", headers)

      if response.code_type < Net::HTTPClientError
        nil
      else
        issue = JSON.parse(response.body)
        state = issue["state"]
        title = issue["title"]
        assignee = issue["assignee"] ? "@#{issue["assignee"]["login"]}" : "unassigned"

        "📌 Context: Issue ##{issue_number} - \"#{title}\" [#{state}] (#{assignee}) - " \
          "https://github.com/#{organization}/#{repo}/issues/#{issue_number}"
      end
    rescue
      nil
    end

    # Check if the installed ruby version meets requirements.
    #
    # @param requirements [Array<String>] a list of version specifiers
    # @return [false, String]
    def ruby_version(*requirements)
      requirement = Gem::Requirement.new(requirements)

      if requirement.satisfied_by?(current_ruby_version)
        "The currently installed version of Ruby #{current_ruby_version} is #{requirement}."
      else
        false
      end
    end

    private

    def now
      @now ||= Time.now
    end

    def spec_set
      @spec_set ||= Bundler.load.specs
    end

    def rubygems_client
      @rubygems_client ||= HttpClientBuilder.build("rubygems.org")
    end

    def github_client
      @github_client ||= HttpClientBuilder.build("api.github.com")
    end

    def github_headers(organization, repo)
      headers = { "Accept" => "application/vnd.github.v3+json" }

      token = github_authorization_token(organization, repo)
      headers["Authorization"] = "token #{token}" if token

      headers
    end

    GITHUB_TOKEN = "SMART_TODO_GITHUB_TOKEN"

    # @return [String, nil]
    def github_authorization_token(organization, repo)
      organization_name = organization.upcase.gsub(/[^A-Z0-9]/, "_")
      repo_name = repo.upcase.gsub(/[^A-Z0-9]/, "_")

      [
        "#{GITHUB_TOKEN}__#{organization_name}__#{repo_name}",
        "#{GITHUB_TOKEN}__#{organization_name}",
        GITHUB_TOKEN,
      ].find do |key|
        token = ENV[key]
        break token unless token.nil? || token.empty?
      end
    end

    def current_ruby_version
      @current_ruby_version ||= Gem::Version.new(RUBY_VERSION)
    end
  end
end
