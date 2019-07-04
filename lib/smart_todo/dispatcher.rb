# frozen_string_literal: true

module SmartTodo
  class Dispatcher
    def initialize(event_message, todo_node, file, options)
      @event_message = event_message
      @todo_node = todo_node
      @options = options
      @file = file
    end

    def dispatch
      user = retrieve_slack_user

      client.post_message(user.dig('user', 'id'), slack_message(user))
    end

    private

    def retrieve_slack_user
      client.lookup_user_by_email(@todo_node.metadata.assignee[0])
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

        You have an assigned TODO in the #{@file} file.
        #{@event_message} and your TODO is now ready to be addressed.
        Here is the associated comment on your TODO:
        ```
        #{@todo_node.comment.strip}
        ```
      EOM
    end

    def unexisting_user
      assignee = @todo_node.metadata.assignee[0]

      "Hello :wave:,\n\n`#{assignee}` had an assigned TODO but this user doesn't exist on Slack anymore."
    end

    def existing_user(user)
      "Hello #{user.dig('user', 'profile', 'first_name')} :wave:,"
    end

    def client
      @client ||= SlackClient.new(@options[:slack_token])
    end
  end
end
