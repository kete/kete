class Slideshow
  def initialize(session_key)
    raise ArgumentError, "Passed in session key not valid. Must be an instance of HashWithIndifferentAccess, but was #{session_key.class.name}." \
      unless session_key.is_a?(HashWithIndifferentAccess)

    @store = session_key
  end

  def reset!
    @store = HashWithIndifferentAccess.new
  end

  methods_to_set_up = %i[
    key
    results
    last_requested
    search_params
    total
    total_pages
    current_page
    image_view_size
    number_per_page
  ]

  methods_to_set_up.each do |method_name|
    define_method(method_name) do
      @store[method_name]
    end

    define_method("#{method_name}=") do |value|
      @store[method_name] = value
    end
  end

  # The logical index of the given item
  def number_of(url)
    index_of(url) + 1
  end

  def number_of_total(url)
    number_of(url) + (current_page - 1) * number_per_page
  end

  def after(url)
    results.at(index_of(url) + 1)
  end

  def before(url)
    index = index_of(url) - 1
    index < 0 ? nil : results.at(index)
  rescue
    raise "#{url} does not appear to be in set #{results.join(", ")}."
  end

  def last?(url)
    results.last == url
  end

  def first?(url)
    results.first == url
  end

  def on_first_page?
    current_page == 1
  end

  def on_last_page?
    current_page == total_pages
  end

  def redirect_to_results_hash
    search_params.reject do |param, value|
      %w[direction search_action].member?(param.to_s)
    end
  end

  def navigable?
    results && results.size > 0
  end

  def in_set?(url)
    results && results.include?(url)
  end

  def last_result?(url)
    last?(url) && on_last_page?
  end

  def first_result?(url)
    first?(url) && on_first_page?
  end

  def next(url = nil)
    if url
      in_set?(url) ? after(url) : nil
    else
      after(last_requested)
    end
  end

  def previous(url = nil)
    if url
      in_set?(url) ? before(url) : nil
    else
      before(last_requested)
    end
  end

  private

  def exists?(index)
    results.at(index) != nil
  end

  # The Array index of the given item
  def index_of(url)
    results.index(url)
  end
end
