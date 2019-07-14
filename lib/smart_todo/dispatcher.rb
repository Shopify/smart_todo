# frozen_string_literal: true

module SmartTodo
  class Dispatcher
    def initialize(event_message, todo_node, file, options)
      @event_message = event_message
      @todo_node = todo_node
      @options = options
      @file = file
      @assignee = @todo_node.metadata.assignee
    end

    def dispatch
      user = if email?
        retrieve_slack_user
      else
        { 'user' => { 'id' => @assignee, 'profile' => { 'first_name' => 'Team' } } }
      end

      client.post_message(user.dig('user', 'id'), slack_message(user))
    end

    private

    def retrieve_slack_user
      client.lookup_user_by_email(@assignee)
    rescue SlackClient::Error => error
      if error.error_code == 'users_not_found'
        { 'user' => { 'id' => @options[:fallback_channel] }, 'fallback' => true }
      else
        raise(error)
      end
    end

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

    def unexisting_user
      "Hello :wave:,\n\n`#{@assignee}` had an assigned TODO but this user doesn't exist on Slack anymore."
    end

    def existing_user(user)
      "Hello #{user.dig('user', 'profile', 'first_name')} :wave:,"
    end

    def client
      @client ||= SlackClient.new(@options[:slack_token])
    end

    def email?
      @assignee.include?("@")
    end
  end
end
