require 'rails/production_console_warning/version'
require 'pry'

module Rails
  module ProductionConsoleWarning
    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    class Configuration
      attr_accessor :custom_text, :condition

      def initialize
        @custom_text = nil
        @condition   = lambda { Rails.env.production? }
      end
    end

    class Railtie < Rails::Railtie
      console do
        configuration = ProductionConsoleWarning.configuration || Configuration.new

        if configuration.condition.call
          render_warning_to_pry_prompt(configuration.custom_text) if defined?(Pry)
          print_warning_to_console(configuration.custom_text)
        end
      end

      def red(text)
        "\033[0;31m#{text}\033[0m"
      end

      def print_warning_to_console(warning_text)
        warning_text ||= 'Running console in PROD environment'
        puts '#' * (warning_text.size + 4)
        puts "# #{red(warning_text)} #"
        puts '#' * (warning_text.size + 4)
      end

      def render_warning_to_pry_prompt(warning_text)
        warning_text ||= 'PRODUCTION'
        old_prompt = Pry.config.prompt
        #env = Pry::Helpers::Text.red(Rails.env.upcase)
        env = Pry::Helpers::Text.red(warning_text)
        Pry.config.prompt = [
          proc {|*a| "#{env} #{old_prompt.first.call(*a)}"},
          proc {|*a| "#{env} #{old_prompt.second.call(*a)}"},
        ]
      end
    end
  end
end
