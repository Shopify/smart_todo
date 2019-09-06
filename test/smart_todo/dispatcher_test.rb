# frozen_string_literal: true

require 'test_helper'

module SmartTodo
  class DispatcherTest < Minitest::Test
    def setup
      @options = { fallback_channel: '#general', slack_token: '123' }
    end

    def test_when_user_exists
      stub_request(:get, /users.lookupByEmail/)
        .to_return(body: JSON.dump(ok: true, user: { id: 'ABC', profile: { first_name: 'John' } }))
      stub_request(:post, /chat.postMessage/)
        .to_return(body: JSON.dump(ok: true))

      dispatcher = Dispatcher.new('Foo', todo_node, 'file.rb', @options)
      dispatcher.dispatch

      assert_requested(:post, /chat.postMessage/) do |request|
        request_body = JSON.parse(request.body)

        assert_match('Hello John', request_body['text'])
        assert_equal('ABC', request_body['channel'])
      end
    end

    def test_when_user_does_not_exist
      stub_request(:get, /users.lookupByEmail/)
        .to_return(body: JSON.dump(ok: false, error: 'users_not_found'))
      stub_request(:post, /chat.postMessage/)
        .to_return(body: JSON.dump(ok: true))

      dispatcher = Dispatcher.new('Foo', todo_node, 'file.rb', @options)
      dispatcher.dispatch

      assert_requested(:post, /chat.postMessage/) do |request|
        request_body = JSON.parse(request.body)

        assert_match("this user or channel doesn't exist on Slack anymore", request_body['text'])
        assert_equal('#general', request_body['channel'])
      end
    end

    def test_when_channel_does_not_exist
      stub_request(:post, /chat.postMessage/)
        .to_return(body: JSON.dump(ok: false, error: 'channel_not_found'))
        .then
        .to_return(body: JSON.dump(ok: true))

      dispatcher = Dispatcher.new('Foo', todo_node('#my_channel'), 'file.rb', @options)
      dispatcher.dispatch

      assert_requested(:post, /chat.postMessage/, body: /`#my_channel` had an assigned TODO/) do |request|
        request_body = JSON.parse(request.body)

        assert_match("this user or channel doesn't exist on Slack anymore", request_body['text'])
        assert_equal('#general', request_body['channel'])
      end
    end

    def test_raises_when_lookup_by_email_fails
      stub_request(:get, /users.lookupByEmail/)
        .to_return(body: JSON.dump(ok: false, error: 'fatal_error'))

      dispatcher = Dispatcher.new('Foo', todo_node, 'file.rb', @options)

      assert_raises(SlackClient::Error) do
        dispatcher.dispatch
      end
    end

    def test_when_user_is_a_slack_channel
      stub_request(:post, /chat.postMessage/)
        .to_return(body: JSON.dump(ok: true))

      dispatcher = Dispatcher.new('Foo', todo_node('#my_channel'), 'file.rb', @options)
      dispatcher.dispatch

      assert_requested(:post, /chat.postMessage/) do |request|
        request_body = JSON.parse(request.body)

        assert_match('Hello Team', request_body['text'])
        assert_equal('#my_channel', request_body['channel'])
      end
    end

    private

    def todo_node(assignee = 'john@example.com')
      ruby_code = <<~EOM
        # TODO(on: date('2011-03-02'), to: '#{assignee}')
        def hello
        end
      EOM

      Parser::CommentParser.new(ruby_code).parse[0]
    end
  end
end
