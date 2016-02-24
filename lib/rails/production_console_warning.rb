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
      attr_accessor :warnings_condintion, :default_warnings, :custom_warnings

      def initialize
        @warnings_condintion = lambda { true }

        @default_warnings = [
          {
            color: 31, #red
            text:  'PRODUCTION',
            condition: lambda { Rails.env.production? }
          },
          {
            color: 34, #blue
            text:  'TEST',
            condition: lambda { Rails.env.test? }
          },
          {
            color: 32, #development
            text:  'DEVELOPMENT',
            condition: lambda { Rails.env.development? }
          }
        ]

        @custom_warnings = []
      end
    end

    class Text
      attr_accessor :text, :color

      def initialize(text, color)
        @text  = text
        @color = color
      end

      def colorize
        "\033[#{color}m#{text}\033[0m"
      end
    end

    class Railtie < Rails::Railtie
      console do
        configuration = ProductionConsoleWarning.configuration || Configuration.new

        if configuration.warnings_condintion.call
          warnings = configuration.default_warnings + configuration.custom_warnings

          warnings.each do |warning|
            if warning[:condition].call
              warning_text = Text.new(warning[:text], warning[:color])

              render_warning_to_pry_prompt(warning_text) if defined?(Pry)
              print_warning_to_console(warning_text)

              break
            end
          end
        end
      end

      def print_warning_to_console(warning_text)
        puts '#' * (warning_text.text.size + 4)
        puts "# #{warning_text.colorize} #"
        puts '#' * (warning_text.text.size + 4)
      end

      def render_warning_to_pry_prompt(warning_text)
        old_prompt = Pry.config.prompt

        Pry.config.prompt = [
          proc {|*a| "#{warning_text.colorize} #{old_prompt.first.call(*a)}"},
          proc {|*a| "#{warning_text.colorize} #{old_prompt.second.call(*a)}"},
        ]
      end
    end
  end
end
