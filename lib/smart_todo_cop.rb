# frozen_string_literal: true

require "smart_todo"

module RuboCop
  module Cop
    module SmartTodo
      # A RuboCop used to restrict the usage of regular TODO comments in code.
      # This Cop does not run by default. It should be added to the RuboCop host's configuration file.
      #
      # @see https://rubocop.readthedocs.io/en/latest/extensions/#loading-extensions
      class SmartTodoCop < Cop
        HELP = "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
        MSG = "Don't write regular TODO comments. Write SmartTodo compatible syntax comments. #{HELP}"

        # @param processed_source [RuboCop::ProcessedSource]
        # @return [void]
        def investigate(processed_source)
          processed_source.comments.each do |comment|
            next unless /^#\sTODO/ =~ comment.text

            metadata = metadata(comment.text)

            if metadata.errors.any?
              add_offense(comment, message: "Invalid TODO format: #{metadata.errors.join(", ")}. #{HELP}")
            elsif !smart_todo?(metadata)
              add_offense(comment)
            elsif (methods = invalid_event_methods(metadata.events)).any?
              add_offense(comment, message: "Invalid event method(s): #{methods.join(", ")}. #{HELP}")
            end
          end
        end

        private

        # @param comment [String]
        # @return [SmartTodo::Parser::Visitor]
        def metadata(comment)
          ::SmartTodo::Parser::MetadataParser.parse(comment.gsub(/^#/, ""))
        end

        # @param metadata [SmartTodo::Parser::Visitor]
        # @return [true, false]
        def smart_todo?(metadata)
          metadata.events.any? &&
            metadata.events.all? { |event| event.is_a?(::SmartTodo::Parser::MethodNode) } &&
            metadata.assignees.any?
        end

        # @param metadata [Array<SmartTodo::Parser::MethodNode>]
        # @return [Array<String>]
        def invalid_event_methods(events)
          events.map(&:method_name).reject { |method| ::SmartTodo::Events.respond_to?(method) }
        end
      end
    end
  end
end
