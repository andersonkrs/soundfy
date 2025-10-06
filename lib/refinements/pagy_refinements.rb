module Refinements
  module PagyRefinements
    refine Pagy do
      def as_json(options = {})
        {
          page: page,
          pages: pages,
          count: count,
          limit: limit,
          prev: prev,
          next: self.next,
          from: from,
          to: to
        }
      end
    end
  end
end
