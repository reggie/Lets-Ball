require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	messageTokens = params[:Body].split
	case messageTokens[0]
	when "-a"
		twiml = Twilio::TwiML::Response.new do |r|
			r.Message "#{messageTokens[1]} was added."
		end
	else
		twiml = Twillio::TwiML::Response.new do |r|
			r.Message "Invalid input sent. Text -h for help."
		end
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


