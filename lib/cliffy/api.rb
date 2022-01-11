require 'set'
require_relative 'internal/wrapper'

module Cliffy
  def self.run *commands, arguments: ARGV, help_points: []
    service = Service.new commands, arguments, help_points, method(:abort), method(:puts)
    service.run
  end

  class Service
    def initialize commands, arguments, help_points, abort_method, puts_method
      @commands = commands
      @arguments = arguments
      @help_points = help_points
      @abort_method = abort_method
      @puts_method = puts_method
    end

    def run
      begin
        validate_commands
        if @arguments.empty?
          show_usage
        elsif @arguments.first == 'help'
          show_help
        else
          run_command
        end
      rescue => e
        @abort_method.call e.to_s
      end
      nil
    end

    private

    # Run Methods

    def validate_commands
      command_names = Set.new
      wrappers.each do |wrapper|
        command_name = wrapper.command_name
        if command_names.include? command_name
          raise "Found more than one command called '#{command_name}'."
        end
        command_names << command_name
        wrapper.validate
      end
    end

    def show_usage
      help_content = "Run `#{executable_name} help <command>` for help with a specific command."
      help_content = [help_content] + @help_points unless @help_points.empty?
      show_titles_and_contents(
        'Usage' => "#{executable_name} <command> [arguments]",
        'Commands' => wrappers.to_h { |wrapper| [wrapper.command_name, wrapper.command_description] },
        'Help' => help_content
      )
    end

    def show_help
      if @arguments.count == 2
        wrapper = wrappers.find { |wrapper| wrapper.command_name == @arguments[1] }
        if wrapper
          help_data = wrapper.generate_help_data executable_name
          show_titles_and_contents help_data
          return
        end
      end
      raise invalid_arguments_message
    end

    def run_command
      wrapper = wrappers.find { |wrapper| wrapper.command_name == @arguments.first }
      if wrapper
        wrapper.run @arguments[1...], executable_name
      else
        raise invalid_arguments_message
      end
    end

    # Helpers

    def wrappers
      unless @wrappers
        @wrappers = @commands.map { |command| Internal::Wrapper.new command }
      end
      @wrappers
    end

    def executable_name
      @executable_name ||= File.basename $PROGRAM_NAME
    end

    def invalid_arguments_message
      @invalid_arguments_message ||= "Invalid arguments. Run `#{executable_name}` for help."
    end

    def show_titles_and_contents titles_and_contents
      key_padding = 0
      titles_and_contents.each do |title, content|
        next unless content.is_a? Hash
        next unless content.count > 0
        longest_key = content.keys.map(&:length).max
        key_padding = longest_key if longest_key > key_padding
      end
      index_format = "    %-#{key_padding}s    %s"
      lines = []
      titles_and_contents.each do |title, content|
        case content
        when String then
          next if content.length < 1
          lines << "#{title}:"
          lines << '    ' + content
        when Array then
          next if content.count < 1
          lines << "#{title}:"
          content.each do |line|
            lines << '    - ' + line
          end
        when Hash then
          next if content.count < 1
          lines << "#{title}:"
          content.each do |key, value|
            line = sprintf index_format, key, value
            lines << line
          end
        end
        lines << ''
      end
      message = lines.join $/
      @puts_method.call message
    end
  end
end
