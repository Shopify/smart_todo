# frozen_string_literal: true

require "smart_todo/parser/metadata_parser"

module RuboCop
  module Cop
    module SmartTodo
      # A RuboCop used to restrict the usage of regular TODO comments in code.
      # This Cop does not run by default. It should be added to the RuboCop host's configuration file.
      #
      # @see https://rubocop.readthedocs.io/en/latest/extensions/#loading-extensions
      class SmartTodoCop < Cop
        MSG = "Don't write regular TODO comments. Write SmartTodo compatible syntax comments." \
          "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"

        # @param processed_source [RuboCop::ProcessedSource]
        # @return [void]
        def investigate(processed_source)
          processed_source.comments.each do |comment|
            next unless /^#\sTODO/ =~ comment.text
            next if smart_todo?(comment.text)

            add_offense(comment)
          end
        end

        # @param comment [String]
        # @return [true, false]
        def smart_todo?(comment)
          metadata = ::SmartTodo::Parser::MetadataParser.parse(comment.gsub(/^#/, ""))

          metadata.events.any? &&
            metadata.events.all? { |event| event.is_a?(::SmartTodo::Parser::MethodNode) } &&
            metadata.assignees.any?
        end
      end
    end
  end
end
