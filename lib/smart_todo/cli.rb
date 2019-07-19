# frozen_string_literal: true

require "optionparser"

module SmartTodo
  # This class is the entrypoint of the SmartTodo library and is responsible
  # to retrieve the command line options as well as iterating over each files/directories
  # to run the +CommentParser+ on.
  class CLI
    def initialize
      @options = {}
    end

    # @param args [Array<String>]
    def run(args = ARGV)
      paths = define_options.parse!(args)
      validate_options!
      paths << '.' if paths.empty?

      paths.each do |path|
        normalize_path(path).each do |file|
          parse_file(file)

          STDOUT.print('.')
          STDOUT.flush
        end
      end
    end

    # @raise [ArgumentError] if the +slack_token+ or the +fallback_channel+
    #   options are not passed to the command line
    # @return [void]
    def validate_options!
      @options[:slack_token] ||= ENV.fetch('SMART_TODO_SLACK_TOKEN') { raise(ArgumentError, 'Missing :slack_token') }

      @options.fetch(:fallback_channel) { raise(ArgumentError, 'Missing :fallback_channel') }
    end

    # @return [OptionParser] an instance of OptionParser
    def define_options
      OptionParser.new do |opts|
        opts.banner = "Usage: smart_todo [options] file_or_path1 file_or_path2 ..."
        opts.on('--slack_token TOKEN') do |token|
          @options[:slack_token] = token
        end
        opts.on('--fallback_channel CHANNEL') do |channel|
          @options[:fallback_channel] = channel
        end
      end
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

    # @param file [String] a path to a file
    def parse_file(file)
      Parser::CommentParser.new(File.read(file, encoding: 'UTF-8')).parse.each do |todo_node|
        event_message = nil
        event_met = todo_node.metadata.events.find do |event|
          event_message = Events.public_send(event.method_name, *event.arguments)
        end

        Dispatcher.new(event_message, todo_node, file, @options).dispatch if event_met
      end
    end
  end
end
