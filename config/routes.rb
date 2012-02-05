RailsProxy::Application.routes.draw do
  post '/hook' => "proxy#hook"
  post '/configs' => "proxy#configs"
end
