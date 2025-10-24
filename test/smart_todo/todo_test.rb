# frozen_string_literal: true

require "test_helper"

module SmartTodo
  class TodoTest < Minitest::Test
    def test_event_can_use_context_returns_true_for_regular_events
      assert(Todo.event_can_use_context?(:date))
      assert(Todo.event_can_use_context?(:gem_release))
      assert(Todo.event_can_use_context?(:gem_bump))
      assert(Todo.event_can_use_context?(:custom_event))
    end

    def test_event_can_use_context_returns_false_for_issue_close
      refute(Todo.event_can_use_context?(:issue_close))
    end

    def test_event_can_use_context_returns_false_for_pull_request_close
      refute(Todo.event_can_use_context?(:pull_request_close))
    end

    def test_event_can_use_context_handles_string_input
      assert(Todo.event_can_use_context?("date"))
      refute(Todo.event_can_use_context?("issue_close"))
      refute(Todo.event_can_use_context?("pull_request_close"))
    end

    def test_events_with_implicit_context_constant_is_frozen
      assert(Todo::EVENTS_WITH_IMPLICIT_CONTEXT.frozen?)
    end

    def test_events_with_implicit_context_contains_expected_events
      assert_equal([:issue_close, :pull_request_close], Todo::EVENTS_WITH_IMPLICIT_CONTEXT)
    end
  end
end