# frozen_string_literal: true

module SmartTodo
  # This module contains all the methods accessible for SmartTodo comments.
  # It is meant to be reopened by the host application in order to define
  # its own events.
  #
  # An event needs to return a +String+ containing the message that will be
  # sent to the TODO assignee or +false+ in case the event hasn't been met.
  #
  # @example Adding a custom event
  #   module SmartTodo
  #     module Events
  #       def trello_card_close(card)
  #         ...
  #       end
  #     end
  #   end
  #
  #   TODO(on: trello_card_close(381), to: 'john@example.com')
  module Events
    extend self

    # Check if the +date+ is in the past
    #
    # @param date [String] a correctly formatted date
    # @return [false, String]
    def date(date)
      Date.met?(date)
    end

    # Check if a new version of +gem_name+ was released with the +requirements+ expected
    #
    # @param gem_name [String]
    # @param requirements [Array<String>] a list of version specifiers
    # @return [false, String]
    def gem_release(gem_name, *requirements)
      GemRelease.new(gem_name, requirements).met?
    end

    # Check if +gem_name+ was bumped to the +requirements+ expected
    #
    # @param gem_name [String]
    # @param requirements [Array<String>] a list of version specifiers
    # @return [false, String]
    def gem_bump(gem_name, *requirements)
      GemBump.new(gem_name, requirements).met?
    end

    # Check if the issue +issue_number+ is closed
    #
    # @param organization [String] the GitHub organization name
    # @param repo [String] the GitHub repo name
    # @param issue_number [String, Integer]
    # @return [false, String]
    def issue_close(organization, repo, issue_number)
      IssueClose.new(organization, repo, issue_number, type: "issues").met?
    end

    # Check if the pull request +pr_number+ is closed
    #
    # @param organization [String] the GitHub organization name
    # @param repo [String] the GitHub repo name
    # @param pr_number [String, Integer]
    # @return [false, String]
    def pull_request_close(organization, repo, pr_number)
      IssueClose.new(organization, repo, pr_number, type: "pulls").met?
    end

    # Check if the installed ruby version meets requirements.
    #
    # @param requirements [Array<String>] a list of version specifiers
    # @return [false, String]
    def ruby_version(*requirements)
      RubyVersion.new(requirements).met?
    end
  end
end
