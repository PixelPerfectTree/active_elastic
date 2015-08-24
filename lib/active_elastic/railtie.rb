require 'rails'
module ActiceElastic
  class Railtie < Rails::Railtie
    rake_tasks do
      load "#{File.dirname(__FILE__)}/../tasks/active_elastic_schema.rake"
    end
  end
end