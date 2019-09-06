# frozen_string_literal: true

module SmartTodo
  module Dispatchers
    class Base
      # Factory pattern to retrive the right dispatcher class.
      #
      # @param dispatcher [String]
      #
      # @return [Class]
      def self.class_for(dispatcher)
        case dispatcher
        when "slack"
          Slack
        when nil
          Slack
        end
      end

      # Subclasses should define what options from the CLI they need in order
      # to properly deliver the message. For instance the Slack dispatcher
      # requires an API key.
      #
      # @param _options [Hash]
      #
      # @return void
      def self.validate_options!(_options)
        raise(NotImplemetedError, 'subclass responsability')
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
        @assignee = @todo_node.metadata.assignee
      end

      # This method gets called when a TODO reminder is expired and needs to be delivered.
      # Dispatchers should implement this method to deliver the message where they need.
      #
      # @return void
      def dispatch
        raise(NotImplemetedError, 'subclass responsability')
      end

      private

      # Prepare the content of the message to send to the TODO assignee
      #
      # @param user [Hash] contain information about a user
      # @return [String]
      def slack_message(user)
        header = if user.key?('fallback')
          unexisting_user
        else
          existing_user
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
        "Hello :wave:,\n\n`#{@assignee}` had an assigned TODO but this user or channel doesn't exist on Slack anymore."
      end

      # @param user [Hash]
      def existing_user
        "Hello :wave:,"
      end
    end
  end
end
