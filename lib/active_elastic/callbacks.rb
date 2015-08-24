module ActiveElastic
  module Callbacks
    def self.included(base)
      base.class_eval do
        after_save lambda { index_document if ActiveElastic::Config.index_document_after_save?  }
        after_destroy lambda { __elasticsearch__.delete_document }
      end
    end
  end
end