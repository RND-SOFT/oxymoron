if defined?(::Rails)
  require "oxymoron/oxymoron_form_builder"
  require "oxymoron/config"
  require "oxymoron/extensions/form_helper"
  require "oxymoron/engine"
end

module Oxymoron
  class Oxymoron

    def initialize
      Rails.application.reload_routes!
      @routes, @states, @resources = {}, {}, {}
      
      @app_routes = Rails.application.routes.routes.select{|route| route.name.present? && route.constraints[:request_method]}
      @app_routes_by_controller = @app_routes.select{|route| ['new', 'edit', 'show', 'index'].exclude?(route.defaults[:action])}.group_by{|route| route.defaults[:controller]}.delete_if {|k,v| k.nil?}
      
      @app_routes.each do |route|
        set_routes route
        set_states route
        set_resources route
      end
    end

    def set_routes route
      @routes[route.name] = {
        defaults: (route.defaults[:params] || {}),
        path: route.path.spec.to_s.gsub('(.:format)', '')
      }

      return @routes
    end

    def set_states route
      if route.constraints[:request_method].match("GET")
        path = route.path.spec.to_s.gsub('(.:format)', '')
        url_matcher = "'#{path}'"

        route.path.required_names.each do |required_name|
          if requirement = route.requirements[required_name.to_sym]
            if requirement.is_a? Regexp
              requirement = requirement.to_s[7..-2]
            end
            url_matcher = path.gsub(':'+required_name, "{#{required_name}:(?:#{requirement})}")
            url_matcher = "$urlMatcherFactoryProvider.compile(\"#{url_matcher}\")"
          end
        end

        @states[route.name] = {
          url: url_matcher,
          templateUrl: path,
          cache: route.defaults[:cache] === false ? false : true
        }
        
        if route.defaults[:controller]
          @states[route.name][:controller] = "#{route.defaults[:controller].camelize.gsub('::', '')}Ctrl as ctrl"
          @states[route.name][:action] = route.defaults[:action]
        end
      end

      return @states
    end

    def set_resources route
      if route.defaults[:action] == 'show'
        path = route.path.spec.to_s.gsub('(.:format)', '')
        @resources[route.name.camelize] = {
          url: path,
          default_params: Hash[route.path.required_names.map{|name| [name, '@'+name]}]
        }

        for_hash = {
          'new'     => {method: 'GET', url: "#{path}/new.json" },
          'edit'    => {method: 'GET', url: "#{path}/edit.json"},
          'update'  => {method: 'PUT'},
          'create'  => {method: 'POST'},
          'destroy' => {method: 'DELETE'}
        }

        if route_by_controller = @app_routes_by_controller[route.defaults[:controller]]
          @app_routes_by_controller[route.defaults[:controller]].each do |route|

            base_path = path.gsub(/:(\w)+/, '').gsub(/\(.*$/, '').gsub('//', '/')
            current_route_path = route.path.spec.to_s.gsub(/:(\w)+/, '').gsub(/\(.*$/, '').gsub('//', '/')

            if (current_route_path.start_with?(base_path))
              for_hash[route.defaults[:action]] ||= {
                url: route.path.spec.to_s.gsub('(.:format)', '.json'),
                isArray: route.defaults[:is_array],
                method: /GET|POST|PUT|PATCH|DELETE/.match(route.constraints[:request_method].to_s).to_s
              }
            end
            
          end
        end
        
        @resources[route.name.camelize][:actions] = for_hash
      end

      return @resources
    end

    def generate file
      template = ERB.new File.read(File.expand_path("../../app/assets/javascripts/oxymoron/#{file}", __FILE__)), nil, "%"

      if Rails.env.production?
        return Uglifier.new.compile(template.result(binding))
      else
        return template.result(binding)
      end
    end

    def render_oxymoron_assets asset_name
      html = File.read("#{Gem.loaded_specs['oxymoron'].full_gem_path}/app/assets/javascripts/oxymoron/#{asset_name}")
      template = ERB.new(html, nil, "%")
      template.result(binding)
    end

    class << self
      def generate file
        Oxymoron.new.generate file
      end
    end
  end

end