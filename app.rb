require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	@phone_numver = params[:From]
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message "#{@phone_number}"
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


