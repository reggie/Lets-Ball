require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	messageTokens = params[:Body].split
	message = ""

	#Cases for different options
	case messageTokens[0]
	when "-a"
		if messageTokens[1] == nil
			message = "No name was given."
		else
			message = "#{messageTokens[1]} was added."
		end
	when "-r"
		message = "You were removed."
	when "-b"
		if messageTokens[2] == nil 
			message = "The ball request was not formatted properly."
		else
			message = "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
		end
	when "-h"
		message = "Valid Inputs:
							\tAdd Baller
							\t-a <name>
							\tRemove Baller
							\t-r <name>
							\tBall Request
							\t-b <location> <time>"
	else
		message = "Invalid input sent. Text -h for help."
	end
	
	#Sends text response
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message message.to_s
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


