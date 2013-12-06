require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message "Response given."
	end
	twiml.text
end

post '/call' do
	twiml = Twilio::TwiML::Response.new do |r|
		r.Reject
	end
end

get '/' do
	"Twilio Time"
end


