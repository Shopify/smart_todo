# frozen_string_literal: true

require "smart_todo"
require "date"

module RuboCop
  module Cop
    module SmartTodo
      # A RuboCop used to restrict the usage of regular TODO comments in code.
      # This Cop does not run by default. It should be added to the RuboCop host's configuration file.
      #
      # @see https://rubocop.readthedocs.io/en/latest/extensions/#loading-extensions
      class SmartTodoCop < Base
        HELP = "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
        MSG = "Don't write regular TODO comments. Write SmartTodo compatible syntax comments. #{HELP}"
        INVESTIGATED_TAGS = ::SmartTodo::CommentParser::SUPPORTED_TAGS +
          ::SmartTodo::CommentParser::SUPPORTED_TAGS.map(&:downcase)
        TODO_PATTERN = /^#\s@?(#{INVESTIGATED_TAGS.join("|")})\b/

        # @param processed_source [RuboCop::ProcessedSource]
        # @return [void]
        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless (match = TODO_PATTERN.match(comment.text))

            if match[1] != match[1].upcase
              add_offense(comment)
              next
            end

            metadata = metadata(comment.text)

            if metadata.errors.any?
              add_offense(comment, message: "Invalid TODO format: #{metadata.errors.join(", ")}. #{HELP}")
            elsif !smart_todo?(metadata)
              add_offense(comment)
            elsif invalid_assignees(metadata.assignees).any?
              add_offense(comment, message: "Invalid event assignee. This method only accepts strings. #{HELP}")
            elsif (invalid_events = validate_events(metadata.events)).any?
              add_offense(comment, message: "#{invalid_events.join(". ")}. #{HELP}")
            end
          end
        end

        private

        # @param comment [String]
        # @return [SmartTodo::Parser::Visitor]
        def metadata(comment)
          ::SmartTodo::Todo.new(comment)
        end

        # @param metadata [SmartTodo::Parser::Visitor]
        # @return [true, false]
        def smart_todo?(metadata)
          has_valid_events = metadata.events.any? &&
            metadata.events.all? { |event| event.is_a?(::SmartTodo::Todo::CallNode) }

          # Allow issue_pin without assignees (to: parameter)
          if has_valid_events && metadata.events.any? { |e| e.method_name == :issue_pin }
            true
          else
            has_valid_events && metadata.assignees.any?
          end
        end

        # @param assignees [Array]
        # @return [Array]
        def invalid_assignees(assignees)
          assignees.reject { |assignee| assignee.is_a?(String) }
        end

        # @param events [Array<SmartTodo::Todo::CallNode>]
        # @return [Array<String>]
        def validate_events(events)
          invalid_methods = events.map(&:method_name).reject { |method| ::SmartTodo::Events.method_defined?(method) }
          return ["Invalid event method(s): #{invalid_methods.join(", ")}"] if invalid_methods.any?

          events.map do |event|
            send(validate_method(event.method_name), event.arguments)
          end.compact
        end

        # @param event_type [Symbol]
        # @return [String]
        def validate_method(event_type)
          "validate_#{event_type}_args"
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if date is invalid, nil if valid
        def validate_date_args(args)
          date = args.first
          Date.parse(date)
          nil
        rescue ArgumentError, TypeError
          "Invalid date format: #{date}"
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_issue_close_args(args)
          validate_fixed_arity_args(args, 3, "issue_close", ["organization", "repo", "issue_number"])
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_issue_pin_args(args)
          validate_fixed_arity_args(args, 3, "issue_pin", ["organization", "repo", "issue_number"])
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_pull_request_close_args(args)
          validate_fixed_arity_args(args, 3, "pull_request_close", ["organization", "repo", "pr_number"])
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_gem_release_args(args)
          validate_gem_args(args, "gem_release")
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_gem_bump_args(args)
          validate_gem_args(args, "gem_bump")
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_ruby_version_args(args)
          if args.empty?
            "Invalid ruby_version event: Expected at least 1 argument (version requirement), got 0"
          elsif !args.all? { |arg| arg.is_a?(String) }
            "Invalid ruby_version event: Version requirements must be strings"
          end
        end

        # Helper method for validating fixed arity events
        def validate_fixed_arity_args(args, expected_count, event_name, arg_names)
          if args.size != expected_count
            message = "Invalid #{event_name} event: Expected #{expected_count} arguments "
            message += "(#{arg_names.join(", ")}), got #{args.size}"
            message
          elsif !args.all? { |arg| arg.is_a?(String) }
            "Invalid #{event_name} event: Arguments must be strings"
          end
        end

        # Helper method for validating gem-related events
        def validate_gem_args(args, event_name)
          if args.empty?
            "Invalid #{event_name} event: Expected at least 1 argument (gem_name), got 0"
          elsif !args[0].is_a?(String)
            "Invalid #{event_name} event: First argument (gem_name) must be a string"
          elsif args.size > 1 && !args[1..].all? { |arg| arg.is_a?(String) }
            "Invalid #{event_name} event: Version requirements must be strings"
          end
        end
      end
    end
  end
end
