module Cliffy
  module Internal
    def self.generate_help_data command, command_name, executable_name
      usage_tokens = [executable_name, command_name]
      parameter_names_and_descriptions = {}
      options_and_descriptions = {}
      
      command.method(:run).parameters.each do |parameter|
        symbol = parameter[1]
        description = command.signature[symbol][:description]
        symbol_name = parameter[1].to_s.gsub '_', '-'
        case parameter.first
        when :req
          usage_tokens << "<#{symbol_name}>"
          parameter_names_and_descriptions[symbol_name] = description
        when :rest
          usage_tokens << "<#{symbol_name}...>"
          parameter_names_and_descriptions[symbol_name] = description
        when :key
          option = "--#{symbol_name}"
          type = command.signature[symbol][:type]
          case type
          when :boolean
            usage_tokens << "[#{option}]"
          when :integer, :float, :string
            usage_tokens << "[#{option} value]"
          when Hash
            sub_symbol_names = type.keys.map { |sub_symbol| sub_symbol.to_s.gsub '_', '-' }.join ' '
            usage_tokens << "[#{option} #{sub_symbol_names}]"
          end
          
          options_and_descriptions[option] = description
        end
      end

      usage = usage_tokens.join ' '
      titles_and_contents = {
        'Description' => command.description,
        'Usage' => usage
      }
      unless parameter_names_and_descriptions.empty?
        titles_and_contents.merge! 'Parameters' => parameter_names_and_descriptions
      end
      unless options_and_descriptions.empty?
        titles_and_contents.merge! 'Options' => options_and_descriptions
      end
      if command.respond_to? :notes
        titles_and_contents.merge! 'Notes' => command.notes
      end
      titles_and_contents
    end
  end
end