begin
  require './config/environment'
rescue StandardError
  exit 1
end

routes = Rails.application.routes.routes.map do |route|
  next unless route.name

  {
    route: route.name,
    required_parts: route.required_parts
  }
end.compact

puts routes.to_json
