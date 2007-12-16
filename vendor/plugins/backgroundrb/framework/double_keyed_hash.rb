class DoubleKeyedHash
  def initialize
    @keys1 = {}
    @internal_hash = {}
  end

  def []=(key1,key2,value)
    @keys1[key2] = key1
    @internal_hash[key1] = value
  end

  def [] key
    @internal_hash[key] || @internal_hash[@keys1[key]]
  end

  def delete(key)
    @keys1.delete(key)
    @internal_hash.delete(key)
  end

  def each
    @internal_hash.each { |key,value| yield(key,value)}
  end
end
