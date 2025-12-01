# frozen_string_literal: true

module SmartTodo
  # A helper class to extract git blame information for a specific line in a file.
  class GitBlame
    class << self
      # Get the author email for a specific line in a file using git blame.
      #
      # @param filepath [String] the path to the file
      # @param line_number [Integer] the line number to blame
      # @return [String, nil] the author email, or nil if git blame fails
      def author_email(filepath, line_number)
        return unless filepath && line_number

        output = run_git_blame(filepath, line_number)
        return unless output

        extract_email(output)
      end

      private

      # Run git blame for a specific line and return the output.
      #
      # @param filepath [String] the path to the file
      # @param line_number [Integer] the line number to blame
      # @return [String, nil] the git blame output, or nil if the command fails
      def run_git_blame(filepath, line_number)
        # Use -L to specify the line range, -e to show email, --porcelain for easy parsing
        command = ["git", "blame", "-L", "#{line_number},#{line_number}", "--porcelain", "--", filepath]

        output, status = Open3.capture2(*command)
        return unless status.success?

        output
      rescue Errno::ENOENT
        # git command not found
        nil
      end

      # Extract the author email from git blame porcelain output.
      #
      # @param output [String] the git blame porcelain output
      # @return [String, nil] the author email, or nil if not found
      def extract_email(output)
        output.each_line do |line|
          next unless line.start_with?("author-mail ")

          # The format is "author-mail <email@example.com>"
          email = line.sub("author-mail ", "").strip
          # Remove angle brackets
          return email.tr("<>", "")
        end

        nil
      end
    end
  end
end
