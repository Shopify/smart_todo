# frozen_string_literal: true

module SmartTodo
  module Dispatchers
    # Dispatcher that sends TODO reminders on Slack. Assignees can be either individual
    # (using the associated slack email address) or a channel.
    class Slack < Base
      def self.validate_options!(options)
        options[:slack_token] ||= ENV.fetch('SMART_TODO_SLACK_TOKEN') { raise(ArgumentError, 'Missing :slack_token') }

        options.fetch(:fallback_channel) { raise(ArgumentError, 'Missing :fallback_channel') }
      end

      # Make a Slack API call to dispatch the message to the user or channel
      #
      # @raise [SlackClient::Error] in case the Slack API returns an error
      #   other than `users_not_found`
      #
      # @return [Hash] the Slack response
      def dispatch
        user = slack_user_or_channel

        client.post_message(user.dig('user', 'id'), slack_message(user))
      rescue SlackClient::Error => error
        if %w(users_not_found channel_not_found).include?(error.error_code)
          user = { 'user' => { 'id' => @options[:fallback_channel] }, 'fallback' => true }
        else
          raise(error)
        end

        client.post_message(user.dig('user', 'id'), slack_message(user))
      end

      private

      # Returns a formatted hash containing either the user id of a slack user or
      # the channel the message should be sent to.
      #
      # @return [Hash] a suited hash containing the user ID for a given individual or a slack channel
      def slack_user_or_channel
        if email?
          client.lookup_user_by_email(@assignee)
        else
          { 'user' => { 'id' => @assignee, 'profile' => { 'first_name' => 'Team' } } }
        end
      end

      # @return [SlackClient] an instance of SlackClient
      def client
        @client ||= SlackClient.new(@options[:slack_token])
      end

      # Check if the TODO's assignee is a specific user or a channel
      #
      # @return [true, false]
      def email?
        @assignee.include?("@")
      end
    end
  end
end
