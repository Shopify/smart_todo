# frozen_string_literal: true

require "net/http"
require "json"

module SmartTodo
  module Events
    # An event that check if a GitHub Pull Request or Issue is closed.
    # This event will make an API call to the GitHub API.
    #
    # If the Pull Request or Issue is on a private repository, exporting a token
    # with the `repos` scope in the +SMART_TODO_GITHUB_TOKEN+ environment variable
    # is required.
    #
    # You can also set a per-org or per-repo token by exporting more specific environment variables:
    # +SMART_TODO_GITHUB_TOKEN__<ORG>+ and +SMART_TODO_GITHUB_TOKEN__<ORG>__<REPO>+
    # The +<ORG>+ and +<REPO>+ parts should be uppercased and use underscores.
    # For example, +Shopify/my-repo+ would become +SMART_TODO_GITHUB_TOKEN__SHOPIFY__MY_REPO=...+.
    class IssueClose
      TOKEN_ENV = "SMART_TODO_GITHUB_TOKEN"

      # @param organization [String]
      # @param repo [String]
      # @param pr_number [String, Integer]
      def initialize(organization, repo, pr_number, type:)
        @url = "/repos/#{organization}/#{repo}/#{type}/#{pr_number}"
        @organization = organization
        @repo = repo
        @pr_number = pr_number
      end

      # @return [String, false]
      def met?
        response = client.get(@url, default_headers)

        if response.code_type < Net::HTTPClientError
          error_message
        elsif pull_request_closed?(response.body)
          message
        else
          false
        end
      end

      # Error message send to Slack in case the Pull Request or Issue couldn't be found.
      #
      # @return [String]
      def error_message
        <<~EOM
          I can't retrieve the information from the PR or Issue *#{@pr_number}* in the
          *#{@organization}/#{@repo}* repository.

          If the repository is a private one, make sure to export the `#{TOKEN_ENV}`
          environment variable with a correct GitHub token.
        EOM
      end

      # @return [String]
      def message
        <<~EOM
          The Pull Request or Issue https://github.com/#{@organization}/#{@repo}/pull/#{@pr_number}
          is now closed, your TODO is ready to be addressed.
        EOM
      end

      private

      # @return [Net::HTTP] an instance of Net::HTTP
      def client
        @client ||= Net::HTTP.new("api.github.com", Net::HTTP.https_default_port).tap do |client|
          client.use_ssl = true
        end
      end

      # @param pull_request [String] the Pull Request or Issue
      #   detail sent back from the GitHub API
      #
      # @return [true, false]
      def pull_request_closed?(pull_request)
        JSON.parse(pull_request)["state"] == "closed"
      end

      # @return [Hash]
      def default_headers
        { "Accept" => "application/vnd.github.v3+json" }.tap do |headers|
          token = authorization_token
          headers["Authorization"] = "token #{token}" if token
        end
      end

      # @return [String, nil]
      def authorization_token
        # Will look in order for:
        # SMART_TODO_GITHUB_TOKEN__ORG__REPO
        # SMART_TODO_GITHUB_TOKEN__ORG
        # SMART_TODO_GITHUB_TOKEN
        parts = [
          TOKEN_ENV,
          @organization.upcase.gsub(/[^A-Z0-9]/, "_"),
          @repo.upcase.gsub(/[^A-Z0-9]/, "_"),
        ]

        (parts.size - 1).downto(0).each do |i|
          key = parts[0..i].join("__")
          token = ENV[key]
          return token unless token.nil? || token.empty?
        end

        nil
      end
    end
  end
end
