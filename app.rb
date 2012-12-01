require 'sinatra'
require './issueTask.rb'
require 'redis'
require 'digest/sha1'

use Rack::Logger

redis = Redis.new

helpers do
  def logger
    request.logger
  end
end

get '/uploadIssue' do
  send_file 'uploadIssue.html'
end

get '/:issueid/:article/key' do
  if (!params[:words])
    status 401
  else
    realWords = redis.hget("articles-words", params[:issueid]+"-"+params[:article])
    if (realWords.downcase == params[:words].downcase)
      key = Digest::SHA1.hexdigest request.ip+params[:article]
      key = key[0, 6].upcase
      redis.sadd(params[:issueid]+"-"+params[:article], key)
      key
    end
  end
end

get '/:issueid/:article' do
  if (!params[:key] || !redis.sismember(params[:issueid]+"-"+params[:article], params[:key]))
    status 401
    return
  end
  send_file 'articles/'+params[:issueid]+"-"+params[:article]+".html"
end

post '/uploadIssue' do
  if params[:authors]
      authors = params[:authors][:tempfile].path
      params[:issue].each_value {|issue|
        logger.info authors
        logger.info issue[:tempfile].path
        IssueTask.perform(authors, issue[:tempfile].path)
      }
  end
end