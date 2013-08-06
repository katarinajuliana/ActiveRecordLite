class MassObject
  def self.set_attrs(*attributes)
    @attributes = []
    attributes.each do |attribute|
      self.send(:attr_accessor, attribute)
      @attributes << attribute
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map! do |result_hash|
      self.new(result_hash)
    end
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        setter_method = attr_name.to_s + "="
        self.send(setter_method.to_sym, value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end

