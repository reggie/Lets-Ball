require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

get '/sms' do
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message "Response given."
	end
	twiml.text
end

get '/' do
	"Twilio Time"
end


