require 'oxymoron/concern'

module Oxymoron
  class Engine < ::Rails::Engine

    initializer 'oxymoron.dependent_on_routes', after: "sprockets.environment" do
      Rails.application.config.after_initialize do

        if Config.rewrite_form_for
          ActionView::Base.send :include, ActionViewExtensions::FormHelperRewrite
        end

        ActionView::Base.send :include, ActionViewExtensions::FormHelper

        module ActionView::Helpers
          class FormBuilder
            include ActionViewExtensions::FormBuilder
          end
        end

        Config.oxymoron_js_path ||= Rails.root.join('app', 'assets', 'javascripts')
        routes_watch unless Rails.env.production?
        write_assets
      end
    end

    initializer 'oxymoron.csrf' do |app|
      ActiveSupport.on_load(:action_controller) do
        include ::Oxymoron::Concern
      end
    end

    private
      def routes_watch
        oxymoron_reloader = ActiveSupport::FileUpdateChecker.new(Dir["#{Rails.root}/config/routes.rb"]) do
          write_assets
        end

        ActionDispatch::Reloader.to_prepare do
          oxymoron_reloader.execute_if_updated
        end
      end

      def write_assets
        file_path = File.join(Config.oxymoron_js_path, "oxymoron.js")

        File.open(file_path, File::RDWR|File::CREAT, 0644) {|f|
          f.flock(File::LOCK_EX)
          f.rewind
          f.write(Oxymoron.generate("oxymoron.js.erb"))
          f.flush
          f.truncate(f.pos)
        }
      end
  end
end