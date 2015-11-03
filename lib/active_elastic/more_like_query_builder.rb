module ActiveElastic
  class MoreLikeQueryBuilder
    def self.build(model, fields, terms, min_term_freq=1, max_query_terms=12)
      query  = {
          query: {
            filtered: {
                query: {
                    more_like_this: {
                        docs: [
                            {
                                _index: model.class.index_name,
                                _type: model.class.to_s.downcase,
                                _id: model.id
                            }
                        ],
                        min_term_freq: min_term_freq,
                        max_query_terms: max_query_terms
                    }
                },
            }
          }
        }

        query[:query][:filtered][:query][:more_like_this][:fields] = fields if fields.is_a?(Array) && !fields.empty?

        if terms.is_a?(Array) && terms.any?
          query[:query][:filtered][:filter] = { term: terms.inject({}) { |terms, current| terms[current.to_sym] = model.send(current.to_sym); terms } }
        elsif terms.is_a?(Hash) && terms.any?
          query[:query][:filtered][:filter] = { term: terms }
        end

        query
    end
  end
end