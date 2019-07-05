💡 SmartTodo 💡
============

Summary
---------

The SmartTodo gem is a library designed to assign specific users on todo's task
written in your codebase and help assignees be reminded when it's time to commit
to their todo's.

If you ever had to write short lived code in your application and need to be reminded about it, the SmartTodo gem is here for you.

Example
---------

Imagine we need to write a temporary piece of code inside a ruby application and need to change it on a specific date. Without SmartTodo, here is what you'll have to do.

<details>
  <summary> 🔴 Without SmartTodo </summary>

   ```ruby
     # TODO: Warning! We need to change the API endpoint on July 1st because the provider
     # is modifying its API.
     def api_call
     end
   ```
</details>

Of course there is a good chance that no one will remember to do it...

-------------------

Comes SmartTodo

<details>
  <summary> ✅ With SmartTodo </summary>

   ```ruby
      # @smart_todo on_date('2019-07-01') > assignee('john@example.com')
      #   The API provider is modifying its endpoint, we need to modify our code.
     def api_call
     end
   ```
</details>

How it works
-------------

SmartTodo uses Meta-Tag formatting and a special syntax to define events that will make your todo to expire as well as assigning a specific user to a TODO.

When an event comes to expiration, SmartTodo send a Slack message to the assigned user of the TODO using his email address. Assigning a user to a SmartTodo is mandatory.

Syntax
-------

1. A SmartTodo always begin with the `@smart_todo` Meta-Tag
2. Define events on your todo, such as `on_date` (see below for a list of built-in events)
3. Assign a user to the todo. Assignment are made like this `> assignee('email')`.
4. Optionally write a comment for your todo. The comment has to be intended below the Meta-Tag.

<details>
  <summary> ✅ Example </summary>

  ```ruby
    # @smart_todo on_date('2019-06-03') > assignee('john@example.com')
      # This is a comment that is part of the SmartTodo
   ```
</details>


You can also chain the events with a `|`. If one of the events comes to expiration, the SmartTodo is considered as expired


<details>
  <summary> ✅ Example with multiple events </summary>

  ```ruby
    # @smart_todo on_date('2019-06-03') | on_gem_release('rails', '5.1.0') > assignee('john@example.com')
      # This is a comment that is part of the SmartTodo
   ```
</details>

Built-in events
-------

An Event is what make your todo to expire and be reminded about it.
The SmartTodo gem comes with few built-in events:

#### on_date
The `on_date` event will expire your todo on a specific **date**. This event expects one `String` argument which is the date at which you want to expire your todo. The **date** argument need to be parsable by Ruby `Time.parse`.

<details>
  <summary> on_date example </summary>

  ```ruby
    # @smart_todo on_date('2019-06-03') > assignee('john@example.com')
      # This is a comment that is part of the SmartTodo
   ```
</details>

#### on_gem_release
The `on_gem_release` event will expire your todo when a specific gem has a new release. This event expects two `String` arguments. The first one is the name of the gem and the second is the version you'd like to monitor.
This event will make a API call to the rubygems.org server.

<details>
  <summary> on_gem_release example </summary>

  ```ruby
    # @smart_todo on_gem_release('rails', '5.2.0') > assignee('john@example.com')
      # This is a comment that is part of the SmartTodo
   ```
</details>

How to run SmartTodo
-----------------------

SmartTodo is meant to be run on your CI as part of your tests. **However**, in order to not get spammed on Slack each time a todo comes to expiration and a CI is triggered, I recommend to run the SmartTodo tool on a 24h schedule. Most if not all CI have a way to schedule builds.

**SmartTodo will only run when the `ENABLE_SMART_TODO` environment variable is present**.
Make sure to export this environment variable in your CI schedule.

SmartTodo can be run with the command line like so `bin/smart_todo --slack_token 123 --fallback_channel '#general'`

Mandatory command line argument
----------------------

The `bin/smart_todo` command line require two mandatory arguments:

1. the `:slack_token`
2. the `:fallback_channel`

The Slack token is used to make API request to send message and the fallback_channel is used in case a todo has an assignee that is not part of your Slack organization anymore.

By default SmartTodo will parse all the files recursively in your root application directory.
You can however control which files/folders you want to parse.
`bin/smart_todo my_folder my_file.rb --slack_token 123 --fallback_channel '#general'`
