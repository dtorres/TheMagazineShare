require 'sinatra'
include FileUtils::Verbose
use Rack::Logger

helpers do
  def logger
    request.logger
  end
end

get '/uploadIssue' do
  send_file 'uploadIssue.html'
end

post '/uploadIssue' do
  logger.info "Holi"
  if params[:authors]
      filename = params[:authors][:filename]
      file = params[:authors][:tempfile]
      logger.info File.join(settings.files, filename)
      File.open(File.join(settings.files, filename), 'wb') {|f| f.write file.read }
  end
end