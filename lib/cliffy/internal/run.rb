require 'set'

module Cliffy
  module Internal
    def self.run command, arguments, command_name, executable_name
      unless command.respond_to? :signature
        command.run
        return
      end

      true_values = ['yes', 'true', '1']
      false_values = ['no', 'false', '0']
      invalid_arguments_message = "Invalid arguments. Run `#{executable_name} help #{command_name}` for help."
      run_method = command.method :run
      signature = command.signature
      remaining_arguments = arguments.dup
      keyword_parameters = {}

      optional_symbols_and_data = signature.filter { |symbol, data| data[:kind] == :optional }
      unless optional_symbols_and_data.empty?
        options_and_symbols = optional_symbols_and_data.to_h do |symbol, data|
          option_name = symbol.to_s.gsub '_', '-'
          option = "--#{option_name}"
          [option, symbol]
        end
        remaining_options = options_and_symbols.keys.to_set
        options = optional_symbols_and_data.keys.map { |key| "--#{key.to_s.gsub '_', '-'}" }.to_set
        queued_arguments = []
        while ! remaining_arguments.empty?
          argument = remaining_arguments.pop
          if argument.start_with?('--') && remaining_options.include?(argument)
            symbol = options_and_symbols[argument]
            data_type = optional_symbols_and_data[symbol][:type]
            value = nil
            case data_type

            when :boolean
              if queued_arguments.empty?
                value = true
              end

            when :integer, :float, :string
              if queued_arguments.count == 1
                queued_argument = queued_arguments.first
                case data_type
                when :integer
                  value = Integer queued_argument, exception: false
                when :float
                  value = Float queued_argument, exception: false
                when :string
                  value = queued_argument
                end
              end
      
            when Hash
              if queued_arguments.count == data_type.count
                sub_symbols_and_values = {}
                queued_arguments.zip(data_type).each do |queued_argument, sub_type|
                  sub_value = nil
                  case sub_type[1]
                  when :boolean
                    sub_value = true if true_values.include? argument
                    sub_value = false if false_values.include? argument
                  when :integer
                    sub_value = Integer queued_argument, exception: false
                  when :float
                    sub_value = Float queued_argument, exception: false
                  when :string
                    sub_value = queued_argument
                  end
                  raise invalid_arguments_message if sub_value == nil
                  sub_symbols_and_values[sub_type.first] = sub_value
                end
                value = sub_symbols_and_values
              end
      
            end
            raise invalid_arguments_message if value === nil
            keyword_parameters[symbol] = value
            remaining_options.delete argument
            queued_arguments = []
          else
            queued_arguments.unshift argument
          end
        end
        remaining_arguments = queued_arguments
      end

      strict_parsing = true
      if command.respond_to?(:configuration) && command.configuration.include?(:strict_parsing)
        strict_parsing = command.configuration[:strict_parsing]
      end
      if strict_parsing
        if remaining_arguments.any? { |argument| argument.start_with? '--' }
          raise invalid_arguments_message
        end
      end

      required_parameters = []
      run_method.parameters.each do |parameter|
        next unless parameter.first == :req
        data = signature[parameter[1]]
        argument = remaining_arguments.shift
        raise invalid_arguments_message if argument == nil
        value = nil
        case data[:type]
        when :boolean
          value = true if true_values.include? argument
          value = false if false_values.include? argument
        when :integer
          value = Integer argument, exception: false
        when :float
          value = Float argument, exception: false
        when :string
          value = argument
        end
        raise invalid_arguments_message if value == nil
        required_parameters << value
      end

      variadic_parameters = []
      variadic_data = signature.values.find { |data| data[:kind] == :variadic }
      if variadic_data
        data_type = variadic_data[:type]
        while ! remaining_arguments.empty?
          argument = remaining_arguments.shift
          value = nil
          case data_type
          when :boolean
            value = true if true_values.include? argument
            value = false if false_values.include? argument
          when :integer
            value = Integer argument, exception: false
          when :float
            value = Float argument, exception: false
          when :string
            value = argument
          end
          raise invalid_arguments_message if value == nil
          variadic_parameters << value
        end
        variadic_count = variadic_parameters.count
        minimum = variadic_data[:minimum]
        raise invalid_arguments_message if minimum && variadic_parameters.count < minimum
        maximum = variadic_data[:maximum]
        raise invalid_arguments_message if maximum && variadic_parameters.count > maximum
      else
        raise invalid_arguments_message unless remaining_arguments.empty?
      end

      positional_parameters = required_parameters + variadic_parameters
      command.run *positional_parameters, **keyword_parameters
    end
  end
end