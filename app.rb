require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	messageTokens = params[:Body].split
	twiml = Twilio::TwiML::Response.new do |r|
		case messageTokens[0]
		when "-a"
			if messageTokens[1] == nil
				r.Message "No name was given."
			else
				r.Message "#{messageTokens[1]} was added."
			end
		when "-r"
			r.Message "#{messageTokens[1]} was removed."
		when "-b"
			if messageTokens[2] == nil 
				r.Message "The ball request was not formatted properly."
			else
				r.Message "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
			end
		when "-h"
			r.Message "Valid Inputs:\n\tAdd Baller\n\t-a <name>\n\tRemove Baller\n\t-r <name>\n\tBall Request\n\t-b <location> <time>"
		else
			r.Message "Invalid input sent. Text -h for help."
		end
		twiml.text
	end
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


