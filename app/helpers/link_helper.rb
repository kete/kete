# frozen_string_literal: true

module LinkHelper
  def basket_aware_url_for(model)
    url_for([model.basket, model])
  end
end
