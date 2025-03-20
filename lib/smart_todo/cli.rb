# frozen_string_literal: true

require "optionparser"
require "etc"

module SmartTodo
  # This class is the entrypoint of the SmartTodo library and is responsible
  # to retrieve the command line options as well as iterating over each files/directories
  # to run the +CommentParser+ on.
  class CLI
    def initialize(dispatcher = nil)
      @options = {}
      @errors = []
      @dispatcher = dispatcher
    end

    # @param args [Array<String>]
    def run(args = ARGV)
      paths = define_options.parse!(args)
      validate_options!

      paths << "." if paths.empty?

      comment_parser = CommentParser.new
      paths.each do |path|
        normalize_path(path).each do |filepath|
          comment_parser.parse_file(filepath)

          $stdout.print(".")
          $stdout.flush
        end
      end

      process_dispatches(process_todos(comment_parser.todos))

      if @errors.empty?
        0
      else
        $stderr.puts "There were errors while checking for TODOs:\n"

        @errors.each do |error|
          $stderr.puts error
        end

        1
      end
    end

    # @raise [ArgumentError] In case an option needed by a dispatcher wasn't provided.
    #
    # @return [void]
    def validate_options!
      dispatcher.validate_options!(@options)
    end

    # @return [OptionParser] an instance of OptionParser
    def define_options
      OptionParser.new do |opts|
        opts.banner = "Usage: smart_todo [options] file_or_path1 file_or_path2 ..."
        opts.on("--slack_token TOKEN") do |token|
          @options[:slack_token] = token
        end
        opts.on("--fallback_channel CHANNEL") do |channel|
          @options[:fallback_channel] = channel
        end
        opts.on("--dispatcher DISPATCHER") do |dispatcher|
          @options[:dispatcher] = dispatcher
        end
        opts.on("--repo [REPO]", "Repository name to include in notifications") do |repo|
          @options[:repo] = repo || File.basename(Dir.pwd)
        end
      end
    end

    # @return [Class] a Dispatchers::Base subclass
    def dispatcher
      @dispatcher ||= Dispatchers::Base.class_for(@options[:dispatcher])
    end

    # @param path [String] a path to a file or directory
    # @return [Array<String>] all the directories the parser should run on
    def normalize_path(path)
      if File.file?(path)
        [path]
      else
        Dir["#{path}/**/*.rb"]
      end
    end

    def process_todos(todos)
      events = Events.new
      dispatches = []

      todos.each do |todo|
        event_message = nil
        event_met = todo.events.find do |event|
          event_message = events.public_send(event.method_name, *event.arguments)
        rescue => e
          message = "Error while parsing #{todo.filepath} on event `#{event.method_name}` " \
            "with arguments #{event.arguments.map(&:inspect)}: " \
            "#{e.message}"

          @errors << message

          nil
        end

        @errors.concat(todo.errors)
        dispatches << [event_message, todo] if event_met
      end

      dispatches
    end

    def process_dispatches(dispatches)
      queue = Queue.new
      dispatches.each { |dispatch| queue << dispatch }

      thread_count = Etc.nprocessors
      thread_count.times { queue << nil }

      threads =
        thread_count.times.map do
          Thread.new do
            Thread.current.abort_on_exception = true

            loop do
              dispatch = queue.pop
              break if dispatch.nil?

              (event_message, todo) = dispatch
              dispatcher.new(event_message, todo, todo.filepath, @options).dispatch
            end
          end
        end

      threads.each(&:join)
    end
  end
end
