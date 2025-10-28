<h3 align="center">
  <img src="https://user-images.githubusercontent.com/8122246/61341925-b936d180-a848-11e9-95c1-0d2f398c51b1.png?raw=true" width="200">
</h3>

[![Build Status](https://github.com/Shopify/smart_todo/workflows/CI/badge.svg)](https://github.com/Shopify/smart_todo/actions?query=workflow%3ACI)

_SmartTodo_  is a library designed to assign users on TODO comments written in your codebase and help assignees be reminded when it's time to commit to their TODO.

Installation
-----------
1) Add the gem in your Gemfile.
```ruby
group :development do
  gem 'smart_todo', require: false # No need to require it
end
```
2) Run `bundle install`


Summary
---------
SmartTodo allows to write TODO comments alongside your code and assign a user to it.
When the TODO's event is met (i.e. a certain date is reached), the TODO's assignee will get pinged on Slack.

**Without SmartTodo**
```ruby
  # TODO: Warning! We need to change the API endpoint on July 1st because the provider
  # is modifying its API.
  def api_call
  end
```

-------------------

**With SmartTodo**
```ruby
  # TODO(on: date('2019-07-01'), to: 'john@example.com')
  #   The API provider is modifying its endpoint, we need to modify our code.
  def api_call
  end
```

You can also add context to your TODOs by linking them to GitHub issues. The `context` attribute
works with all events:

```ruby
  # TODO(on: date('2025-01-01'), to: 'team@example.com', context: "shopify/smart_todo#108")
  #   Implement the caching strategy discussed in the issue
  def process_order
  end

  # TODO(on: gem_release('rails', '> 7.2'), to: 'dev@example.com', context: "rails/rails#456")
  #   Upgrade to new Rails version as discussed in the issue
  def legacy_method
  end

  # TODO(on: issue_close('shopify', 'smart_todo', '123'), to: 'team@example.com', context: "shopify/other-repo#456")
  #   Update once the referenced issue is closed, see related context for details
  def feature_flag
  end
```

When the TODO is triggered, the linked issue's title, state, and assignee will be included in the notification.

Documentation
----------------
Please check out the GitHub [wiki](https://github.com/Shopify/smart_todo/wiki) for documentation and example on how to setup SmartTodo in your project.

License
--------
This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE.txt) file.
