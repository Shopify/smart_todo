# frozen_string_literal: true

module SmartTodo
  module Dispatchers
    # Dispatcher that sends TODO reminders on Slack. Assignees can be either individual
    # (using the associated slack email address) or a channel.
    class Slack < Base
      class << self
        def validate_options!(options)
          options[:slack_token] ||= ENV.fetch("SMART_TODO_SLACK_TOKEN", "")
          raise(ArgumentError, "Missing :slack_token") if options[:slack_token].empty?

          options.fetch(:fallback_channel) { raise(ArgumentError, "Missing :fallback_channel") }
        end
      end

      # Make a Slack API call to dispatch the message to each assignee
      #
      # @raise [SlackClient::Error] in case the Slack API returns an error
      #   other than `users_not_found`
      #
      # @return [Array] Slack response for each assignee a message was sent to
      def dispatch
        owner_slack_id = lookup_todo_owner
        @assignees.each do |assignee|
          dispatch_one(assignee, owner_slack_id)
        end
      end

      # Make a Slack API call to dispatch the message to the user or channel
      #
      # @raise [SlackClient::Error] in case the Slack API returns an error
      #   other than `users_not_found`
      #
      # @param assignee [String] the assignee handle string
      # @param owner_slack_id [String, nil] the Slack user ID of the TODO owner
      # @return [Hash] the Slack response
      def dispatch_one(assignee, owner_slack_id = nil)
        user = slack_user_or_channel(assignee)

        return unless user

        begin
          client.post_message(user.dig("user", "id"), slack_message(user, assignee, owner: owner_slack_id))
        rescue SlackClient::Error => error
          user = handle_slack_error(error, "Error dispatching message")
          retry
        rescue Net::HTTPError => error
          $stderr.puts "Error dispatching message: #{error.message}"
          $stderr.puts "Response: #{error.response.body}"
        end
      end

      private

      # Look up the Slack user ID of the person who added the TODO comment
      # using git blame to find the author's email.
      #
      # @return [String, nil] the Slack user ID, or nil if not found
      def lookup_todo_owner
        author_email = GitBlame.author_email(@file, @todo_node.start_line)
        return unless author_email

        response = client.lookup_user_by_email(author_email)
        response.dig("user", "id")
      rescue SlackClient::Error, Net::HTTPError
        # If we can't find the owner, just skip including them in the message
        nil
      end

      # Returns a formatted hash containing either the user id of a slack user or
      # the channel the message should be sent to.
      #
      # @return [Hash] a suited hash containing the user ID for a given individual or a slack channel
      def slack_user_or_channel(assignee)
        if assignee.include?("@")
          client.lookup_user_by_email(assignee)
        else
          { "user" => { "id" => assignee } }
        end
      rescue SlackClient::Error => error
        handle_slack_error(error, "Error finding user or channel")
      rescue Net::HTTPError => error
        $stderr.puts "Error finding user or channel: #{error.message}"
        $stderr.puts "Response: #{error.response.body}"
      end

      # @return [SlackClient] an instance of SlackClient
      def client
        @client ||= SlackClient.new(@options[:slack_token])
      end

      def handle_slack_error(error, message)
        if ["users_not_found", "channel_not_found", "is_archived"].include?(error.error_code)
          { "user" => { "id" => @options[:fallback_channel] }, "fallback" => true }
        else
          $stderr.puts "#{message}: #{error.message}"
        end
      end
    end
  end
end
