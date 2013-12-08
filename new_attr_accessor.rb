class Object
  def new_attr_accessor(*args) #an array of symbols

    args.each do |attribute|
      define_method("#{attribute}") do
        self.instance_variable_get("@#{attribute.to_s}")
      end
      define_method("#{attribute}=") do |var_name|
        self.instance_variable_set("@#{attribute.to_s}", var_name)
      end
    end
  end
end

class Dog
  # attr_writer :name, :age
  new_attr_accessor :name, :age

  def initialize
  end
end



