class Object
  def self.metaclass; class << self; self; end; end

  def self.iattr_accessor *args
    metaclass.instance_eval do
      attr_accessor *args
      args.each do |attr|
        define_method("set_#{attr}") do |b_value|
          self.send("#{attr}=",b_value)
        end
      end
    end

    args.each do |attr|
      class_eval do
        define_method(attr) do
          self.class.send(attr)
        end
        define_method("#{attr}=") do |b_value|
          self.class.send("#{attr}=",b_value)
        end
      end
    end
  end
end


