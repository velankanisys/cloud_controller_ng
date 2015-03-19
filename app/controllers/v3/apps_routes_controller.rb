require 'queries/add_route_fetcher'
require 'actions/add_route_to_app'
require 'presenters/v3/route_presenter'

module VCAP::CloudController
  class AppsRoutesController < RestController::BaseController
    get '/v3/apps/:guid/routes', :list
    def list(app_guid)
      check_read_permissions!

      app_model = AppFetcher.new(current_user).fetch(app_guid)
      app_not_found! if app_model.nil?

      routes_json = RoutePresenter.new.present_json_list(app_model.routes, '/v3/routes')
      [HTTP::OK, routes_json]
    end

    put '/v3/apps/:guid/routes', :add_route
    def add_route(app_guid)
      check_write_permissions!

      opts = MultiJson.load(body)
      app_model, route = AddRouteFetcher.new(current_user).fetch(app_guid, opts['route_guid'])
      app_not_found! if app_model.nil?
      route_not_found! if route.nil?

      AddRouteToApp.new(app_model).add(route)
      [HTTP::NO_CONTENT]
    end

    def app_not_found!
      raise VCAP::Errors::ApiError.new_from_details('ResourceNotFound', 'App not found')
    end

    def route_not_found!
      raise VCAP::Errors::ApiError.new_from_details('ResourceNotFound', 'Route not found')
    end
  end
end
