require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	sender = params[:From]
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message "#{sender} texed me."
	end
	twiml.text
end

post '/call' do
	twiml = Twilio::TwiML::Response.new do |r|
		r.Reject
	end
	twiml.text
end

get '/' do
	"Twilio Time"
end


