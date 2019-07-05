# frozen_string_literal: true

require "optionparser"

module SmartTodo
  class CLI
    def initialize
      @options = {}
    end

    def run(args = ARGV)
      paths = define_options.parse!(args, into: @options)
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

    def validate_options!
      @options[:slack_token] ||= ENV.fetch('SMART_TODO_SLACK_TOKEN') { raise(ArgumentError, 'Missing :slack_token') }

      @options.fetch(:fallback_channel) { raise(ArgumentError, 'Missing :fallback_channel') }
    end

    def define_options
      OptionParser.new do |opts|
        opts.banner = "Usage: smart_todo [options] file_or_path1 file_or_path2 ..."
        opts.on('--slack_token TOKEN')
        opts.on('--fallback_channel CHANNEL')
      end
    end

    def normalize_path(path)
      if File.file?(path)
        [path]
      else
        Dir["#{path}/**/*.rb"]
      end
    end

    def parse_file(file)
      Parser::CommentParser.new(File.read(file)).parse.each do |todo_node|
        event_message = nil
        event_met = todo_node.metadata.events.find do |event|
          event_message = Events.public_send(event.method_name, *event.arguments)
        end

        Dispatcher.new(event_message, todo_node, file, @options).dispatch if event_met
      end
    end
  end
end
