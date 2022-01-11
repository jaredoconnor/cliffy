module Cliffy
  module Internal
    def self.validate command
      prefix = "Error validating '#{command.class}' command:"
      raise "#{prefix} No run method." unless command.respond_to? :run
      raise "#{prefix} No description." unless command.respond_to? :description
      description = command.description
      unless description.is_a?(String) && ! description.empty? && description.lines.count == 1
        raise "#{prefix} Invalid description."
      end

      if command.respond_to? :notes
        notes = command.notes
        raise "#{prefix} Notes is not an array." unless notes.is_a?(Array)
        notes.each_with_index do |note, index|
          unless note.is_a?(String) && ! note.empty? && note.lines.count == 1
            raise "#{prefix} Invalid note at index #{index}."
          end
        end
      end

      parameters = command.method(:run).parameters
      return if parameters.empty?

      unless command.respond_to?(:signature) && command.signature.is_a?(Hash)
        raise "#{prefix} Signature missing or not defined correctly."
      end

      command.signature.each do |symbol, data|
        raise "#{prefix} signature key '#{symbol}' is not a symbol." unless symbol.is_a? Symbol
        data_prefix = "#{prefix} Signature data for '#{symbol}'"
        raise "#{data_prefix} is not a hash." unless data.is_a? Hash
        raise "#{data_prefix} does not have a kind." unless data.include? :kind
        raise "#{data_prefix} does not have a type." unless data.include? :type
        raise "#{data_prefix} does not have a description." unless data.include? :description

        data_kind = data[:kind]
        data_type = data[:type]
        data_description = data[:description]

        case data_kind
        when :required, :optional
          valid_data_keys = [:kind, :description, :type]
        when :variadic
          valid_data_keys = [:kind, :description, :type, :minimum, :maximum]
        else
          raise "#{data_prefix} has an invalid kind."
        end

        unless data.keys.to_set.subset? valid_data_keys.to_set
          raise "#{data_prefix} contains an unrecognized key."
        end
        unless data_description.is_a?(String) && ! data_description.empty? && data_description.lines.count == 1
          raise "#{data_prefix} does not have a valid description."
        end

        primitives = [:string, :integer, :float, :boolean]
        case data_kind
        when :required, :variadic
          unless primitives.include? data_type
            raise "#{data_prefix} is of kind '#{data_kind}' and must have a valid primitive type."
          end
        when :optional
          case data_type
          when :string, :integer, :float, :boolean
          when Hash
            unless data_type.keys.all? { |key| key.is_a? Symbol }
              raise "#{data_prefix} contains an invalid key in the value hash."
            end
            unless data_type.values.all? { |value| primitives.include? value }
              raise "#{data_prefix} contains an invalid value in the value hash."
            end
          else
            raise "#{data_prefix} is of kind 'optional' and must have a valid primitive or hash type."
          end
        end

        if data_kind == :variadic
          if data.include? :minimum
            minimum = data[:minimum]
            unless minimum.is_a?(Integer) && minimum >= 0
              raise "#{data_prefix} has an invalid minimum value."
            end
          else
            minimum = 0
          end
          if data.include? :maximum
            maximum = data[:maximum]
            unless maximum.is_a?(Integer) && maximum >= 0 && maximum > minimum
              raise "#{data_prefix} has an invalid maximum value."
            end
          end
        end
      end

      method_symbols = parameters.map { |parameter| parameter[1] }.to_set
      signature_symbols = command.signature.keys.to_set
      missing_method_symbols = signature_symbols - method_symbols
      missing_signature_symbols = method_symbols - signature_symbols
      unless missing_method_symbols.empty?
        raise "#{prefix} Symbols missing from run method that are in signature: #{missing_method_symbols.join ', '}"
      end
      unless missing_signature_symbols.empty?
        raise "#{prefix} Symbols missing from signature that are in run method: #{missing_signature_symbols.join ', '}"
      end

      found_req = false
      found_rest = false
      found_key = false
      parameters.each do |parameter|
        parameter_prefix = "#{prefix} '#{parameter[1]}'"
        case parameter.first
        when :req
          kind = :required
          found_req = true
          raise "#{prefix} Required positional after variadic." if found_rest
          raise "#{prefix} Required positional after required keyword." if found_key
        when :rest
          kind = :variadic
          found_rest = true
          raise "#{prefix} Variadic after required keyword." if found_key
        when :key
          kind = :optional
          found_key = true
        else
          raise "#{parameter_prefix} is not a supported kind of method parameter."
        end
        unless command.signature[parameter[1]][:kind] == kind
          raise "#{parameter_prefix} should have a kind of '#{kind}', in the signature."
        end
      end
    end
  end
end