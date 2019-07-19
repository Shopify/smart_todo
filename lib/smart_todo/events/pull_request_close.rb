# frozen_string_literal: true

require 'net/http'
require 'json'

module SmartTodo
  module Events
    class PullRequestClose
      TOKEN_ENV = 'SMART_TODO_GITHUB_TOKEN'

      def initialize(organization, repo, pr_number)
        @url = "/repos/#{organization}/#{repo}/pulls/#{pr_number}"
        @organization = organization
        @repo = repo
        @pr_number = pr_number
      end

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

      def error_message
        <<~EOM
          I can't retrieve the information from the PR or Issue *#{@pr_number}* in the
          *#{@organization}/#{@repo}* repository.

          If the repository is a private one, make sure to export the `#{TOKEN_ENV}`
          environment variable with a correct GitHub token.
        EOM
      end

      def message
        <<~EOM
          The Pull Request or Issue https://github.com/#{@organization}/#{@repo}/pull/#{@pr_number}
          is now closed, your TODO is ready to be addressed.
        EOM
      end

      private

      def client
        @client ||= Net::HTTP.new('api.github.com', Net::HTTP.https_default_port).tap do |client|
          client.use_ssl = true
        end
      end

      def pull_request_closed?(pull_request)
        JSON.parse(pull_request)['state'] == 'closed'
      end

      def default_headers
        { 'Accept' => 'application/vnd.github.v3+json' }.tap do |headers|
          headers['Authorization'] = "token #{ENV[TOKEN_ENV]}" if ENV[TOKEN_ENV]
        end
      end
    end
  end
end
