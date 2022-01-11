require_relative 'generate_help_data'
require_relative 'run'
require_relative 'validate'

module Cliffy
  module Internal
    class Wrapper
      def initialize command
        @command = command
      end

      def command_name
        @command_name ||= @command.class.to_s.split('::').last.gsub(/([A-Z][a-z]+)([A-Z][a-z]+)/, '\1-\2').downcase
      end

      def command_description
        @command.description
      end

      def validate
        Internal::validate @command
      end

      def generate_help_data executable_name
        Internal::generate_help_data @command, command_name, executable_name
      end

      def run arguments, executable_name
        Internal::run @command, arguments, command_name, executable_name
      end
    end
  end
end