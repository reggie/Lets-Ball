require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	#Stores the text as tokens split by spaces
	messageTokens = params[:Body].split
	message = ""

	#Cases for different options
	case messageTokens[0]
	when "-a"	#Add yourself to the database
		if messageTokens[1] == nil
			message = "No name was given."
		else
			message = "#{messageTokens[1]} was added."
		end
	when "-r" #Remove youself from the database
		message = "You were removed."
	when "-b"	#Send out a ball request
		if messageTokens[2] == nil 
			message = "The ball request was not formatted properly."
		else
			message = "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
		end
	when "-h"	#Ask for help 
		message = "Valid Inputs:\n"  +
							"\tAdd Baller\n"   +
							"\t-a <name>\n"    +
							"\tRemove Baller\n"+
							"\t-r <name>\n"    +
							"\tBall Request\n" +
							"\t-b <location> <time>"
	else	#Default case to alert improper usage
		message = "Invalid input sent. Text -h for help."
	end
	
	#Sends text response
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message message.to_s
	end
	twiml.text
end

post '/call' 
	#Makes app hangup if called
	twiml = Twilio::TwiML::Response.new do |r|
		r.Reject
	end
	twiml.text
end

get '/' do
	"Twilio Time"
end
