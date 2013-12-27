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
	when "-r"
		twiml = Twilio::TwiML::Response.new do |r|
			r.Message "#{messageTokens[1]} was removed."
		end
	when "-b"
		twiml = Twilio::TwiML::Response.new do |r|
			r.Message "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
		end
	when "-h"
		twiml = Twilio::TwiML::Response.new do |r|
			r.Message "Valid Inputs:\n\tAdd\n\t-a <name>\n\tRemove\n\t-r <name>\n\tBall\n\t-b <location> <time>"
		end
	else
		twiml = Twilio::TwiML::Response.new do |r|
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


