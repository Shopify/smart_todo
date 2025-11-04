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

        file_reference = generate_file_reference

        <<~EOM
          #{header}

          You have an assigned TODO#{file_reference}#{repo}.
          #{@event_message}

          Here is the associated comment on your TODO:

          ```
          #{@todo_node.comment.strip}
          ```
        EOM
      end

      # Generates a file reference with link (if in a GitHub repo) or readable line reference
      #
      # @return [String]
      def generate_file_reference
        # Find the git repository root from the file's path, not from Dir.pwd
        # This ensures we detect the correct repo even when smart_todo is run
        # from a different directory than the repo root
        git_root = GitUtils.find_git_root(@file)

        # Try to generate a GitHub link if we have a line number and found a git repo
        if @todo_node.line_number && git_root
          github_link = GitUtils.generate_github_link(@file, @todo_node.line_number, git_root)

          if github_link
            " at <#{github_link}|#{@file}:#{@todo_node.line_number}>"
          else
            " in the `#{@file}` file on line #{@todo_node.line_number}"
          end
        elsif @todo_node.line_number
          # Have line number but no git repo
          " in the `#{@file}` file on line #{@todo_node.line_number}"
        else
          # Fallback to just the file name if no line number
          " in the `#{@file}` file"
        end
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
    end
  end
end
