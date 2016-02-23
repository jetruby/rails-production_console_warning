require 'rails/production_console_warning/version'
require 'pry'

module Rails
  module ProductionConsoleWarning
    class Railtie < Rails::Railtie
      console do
        render_warning_to_pry_prompt if defined?(Pry)
        print_warning_to_console
      end

      def red(text)
        "\033[0;31m#{text}\033[0m"
      end

      def print_warning_to_console
        str = "Running console in PROD environment"
        puts '#' * (str.size + 4)
        puts "# #{red(str)} #"
        puts '#' * (str.size + 4)
      end

      def render_warning_to_pry_prompt
        old_prompt = Pry.config.prompt
        #env = Pry::Helpers::Text.red(Rails.env.upcase)
        env = Pry::Helpers::Text.red('PRODUCTION')
        Pry.config.prompt = [
          proc {|*a| "#{env} #{old_prompt.first.call(*a)}"},
          proc {|*a| "#{env} #{old_prompt.second.call(*a)}"},
        ]
      end
    end
  end
end
