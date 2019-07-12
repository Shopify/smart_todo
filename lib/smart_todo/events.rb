# frozen_string_literal: true

module SmartTodo
  module Events
    extend self

    def on_date(date)
      Date.met?(date)
    end

    def on_gem_release(gem_name, version)
      GemRelease.new(gem_name, version).met?
    end

    def on_pull_request_closed(organization, repo, pr_number)
      PullRequestClosed.new(organization, repo, pr_number).met?
    end
    alias_method :on_issue_close, :on_pull_request_closed
  end
end
