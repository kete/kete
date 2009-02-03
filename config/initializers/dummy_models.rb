# Sometimes we don't want to hit the database, but need a mocked Object
# (for example, related items needs one several methods deep needs a topic)
# Whatever methods you call on it, it'll send to itself
# example:
# dt = DummyModel.new({ :id => 16, :basket => @current_basket })
class DummyModel
  [:id, :basket].each { |attribute| attr_accessor attribute }
  def initialize(options={})
    options.each { |k,v| send("#{k}=".to_sym, v) }
  end
  def to_i; id; end
end
