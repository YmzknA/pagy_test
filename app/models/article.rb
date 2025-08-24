class Article < ApplicationRecord
  paginates_per 25
  max_paginates_per 100
  max_pages 1000
end
