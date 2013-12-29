require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	messageTokens = params[:Body].split
	case messageTokens[0]
	message = ""
	when "-a"
		if messageTokens[1] == nil
			message = "No name was given."
		else
			message = "#{messageTokens[1]} was added."
		end
	when "-r"
		message = "#{messageTokens[1]} was removed."
	when "-b"
		if messageTokens[2] == nil 
			message = "The ball request was not formatted properly."
		else
			message = "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
		end
	when "-h"
		message = "Valid Inputs:\n\tAdd Baller\n\t-a <name>\n\tRemove Baller\n\t-r <name>\n\tBall Request\n\t-b <location> <time>"
	else
		message =  "Invalid input sent. Text -h for help."
	end
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message message
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


