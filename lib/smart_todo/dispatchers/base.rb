# frozen_string_literal: true

module SmartTodo
  module Dispatchers
    class Base
      class << self
        # Factory pattern to retrieve the right dispatcher class.
        #
        # @param dispatcher [String]
        #
        # @return [Class]
        def class_for(dispatcher)
          case dispatcher
          when "slack"
            Slack
          when nil, "output"
            Output
          end
        end

        # Subclasses should define what options from the CLI they need in order
        # to properly deliver the message. For instance the Slack dispatcher
        # requires an API key.
        #
        # @param _options [Hash]
        #
        # @return void
        def validate_options!(_options)
          raise(NotImplemetedError, "subclass responsability")
        end
      end

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
        @assignees = @todo_node.assignees
      end

      # This method gets called when a TODO reminder is expired and needs to be delivered.
      # Dispatchers should implement this method to deliver the message where they need.
      #
      # @return void
      def dispatch
        raise(NotImplemetedError, "subclass responsability")
      end

      private

      # Prepare the content of the message to send to the TODO assignee
      #
      # @param user [Hash] contain information about a user
      # @param assignee [String] original string handle the slack message should be sent
      # @return [String]
      def slack_message(user, assignee)
        header = if user.key?("fallback")
          unexisting_user(assignee)
        else
          existing_user
        end

        message = <<~EOM
          #{header}

          You have an assigned TODO in #{slack_file_reference(@todo_node)}#{repo}.
          #{@event_message}
        EOM

        comment = @todo_node.comment.strip
        unless comment.empty?
          message += <<~EOM

            Here is the associated comment on your TODO:

            ```
            #{comment}
            ```
          EOM
        end

        message
      end

      # Message in case a TODO's assignee doesn't exist in the Slack organization
      #
      # @param user [Hash]
      # @return [String]
      def unexisting_user(assignee)
        "Hello :wave:,\n\n`#{assignee}` had an assigned TODO but this user or channel doesn't exist on Slack anymore."
      end

      # Hello message for user actually existing in the organization
      def existing_user
        "Hello :wave:,"
      end

      def repo
        repo = @options[:repo]
        return unless repo

        unless repo.empty?
          " in repository `#{repo}`"
        end
      end

      # Format file reference for Slack
      # Uses deep link if available, otherwise falls back to code-formatted path
      def slack_file_reference(todo)
        link = DeepLink.for_todo(todo)
        if link
          "<#{link.url}|#{link.display}>"
        else
          "`#{todo.file_reference}`"
        end
      end
    end
  end
end
