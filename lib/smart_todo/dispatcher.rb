# frozen_string_literal: true

module SmartTodo
  # The Dispatcher handles the logic to send the Slack message
  # to the assignee once its TODO came to expiration.
  class Dispatcher
    # @param event_message [String] the success message associated
    #   a specific event
    # @param todo_node [SmartTodo::Parser::TodoNode]
    # @param file [String] the file containing the TODO
    # @param options [Hash]
    def initialize(event_message, todo_node, file, options)
      @event_message = event_message
      @todo_node = todo_node
      @options = options
      @file = file
      @assignee = @todo_node.metadata.assignee
    end

    # Make a Slack API call to dispatch the message to the user or channel
    #
    # @return [Hash] the Slack response
    def dispatch
      user = if email?
        retrieve_slack_user
      else
        { 'user' => { 'id' => @assignee, 'profile' => { 'first_name' => 'Team' } } }
      end

      client.post_message(user.dig('user', 'id'), slack_message(user))
    end

    private

    # Retrieve the unique identifier of a Slack user with his email address
    #
    # @return [Hash] the Slack response containing the user ID
    # @raise [SlackClient::Error] in case the Slack API returns an error
    #   other than `users_not_found`
    def retrieve_slack_user
      client.lookup_user_by_email(@assignee)
    rescue SlackClient::Error => error
      if error.error_code == 'users_not_found'
        { 'user' => { 'id' => @options[:fallback_channel] }, 'fallback' => true }
      else
        raise(error)
      end
    end

    # Prepare the content of the message to send to the TODO assignee
    #
    # @param user [Hash] contain information about a user
    # @return [String]
    def slack_message(user)
      header = if user.key?('fallback')
        unexisting_user
      else
        existing_user(user)
      end

      <<~EOM
        #{header}

        You have an assigned TODO in the `#{@file}` file.
        #{@event_message}

        Here is the associated comment on your TODO:

        ```
        #{@todo_node.comment.strip}
        ```
      EOM
    end

    # Message in case a TODO's assignee doesn't exist in the Slack organization
    #
    # @return [String]
    def unexisting_user
      "Hello :wave:,\n\n`#{@assignee}` had an assigned TODO but this user doesn't exist on Slack anymore."
    end

    # @param user [Hash]
    def existing_user(user)
      "Hello #{user.dig('user', 'profile', 'first_name')} :wave:,"
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
