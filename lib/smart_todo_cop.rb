# frozen_string_literal: true

require 'smart_todo/parser/metadata_parser'

module RuboCop
  module Cop
    module SmartTodo
      class SmartTodoCop < Cop
        MSG = "Don't write regular TODO comments. Write SmartTodo compatible syntax comments." \
              "For more info please look at https://github.com/shopify/smart_todo"

        def investigate(processed_source)
          processed_source.comments.each do |comment|
            next unless /^#\sTODO/.match?(comment.text)
            next if smart_todo?(comment.text)

            add_offense(comment)
          end
        end

        def smart_todo?(comment)
          metadata = ::SmartTodo::Parser::MetadataParser.parse(comment.gsub(/^#/, ''))

          metadata.events.any?
        end
      end
    end
  end
end
