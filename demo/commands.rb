class HelloWorld
  def description
    'A bare minimum command'
  end

  def run
    puts 'Hello world.'
  end
end

class PrintCar
  def description
    'A comprehensive command'
  end

  def signature
    {
      brand: { kind: :required, description: 'The brand of the car', type: :string },
      year: { kind: :required, description: 'Year of manufacture', type: :integer },
      imported: { kind: :required, description: 'Whether or not the car is imported', type: :boolean },
      features: { kind: :variadic, description: 'Features the car has', type: :string, minimum: 1, maximum: 2 },
      broken: { kind: :optional, description: 'The car does not work', type: :boolean },
      miles: { kind: :optional, description: 'How many miles the car has traveled', type: :float },
      owner: { kind: :optional, description: 'The name of the owner', type: :string },
      last_owner_miles: { kind: :optional, description: 'The name of the last owner and the miles when sold', type: { name: :string, miles: :float }}
    }
  end

  def notes
    [
      'This command has a variadic parameter.'
    ]
  end

  def run brand, year, imported, *features, broken: false, miles: 0.0, owner: nil, last_owner_miles: nil
    puts "Brand: #{brand}"
    puts "Year: #{year}"
    puts "Imported: #{imported}"
    puts "Features: #{features}"
    puts "Broken: #{broken}"
    puts "Miles: #{miles}"
    puts "Owner: #{owner}"
    puts "Last Owner Miles: #{last_owner_miles}"
  end
end