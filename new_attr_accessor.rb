class Object
  def self.new_attr_accessor(*args)
    args.each do |arg|
      instance_var = "@" + arg.to_s
      setter_name = arg.to_s + "="

      get_var = Proc.new {self.instance_variable_get(instance_var)}
      self.send(:define_method, arg, &get_var)

      set_var = Proc.new { |value| self.instance_variable_set(instance_var.to_sym, value)}
      self.send(:define_method, setter_name, &set_var)
    end
  end

end

class Cat
  new_attr_accessor :name, :color

  def initialize(name, color)
    @name, @color = name, color
  end
end