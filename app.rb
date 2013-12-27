require 'rubygems'
require 'twilio-ruby'
require 'sinatra'

post '/sms' do
	messageTokens = params[:Body].split
	case messageTokens[0]
	when "-a"
		if messageTokens[1] == nil
			twiml = Twilio::TwiML::Response.new do |r|
				r.Message "No name was given."
			end
		else
			twiml = Twilio::TwiML::Response.new do |r|
				r.Message "#{messageTokens[1]} was added."
			end
		end
	when "-r"
		if messageTokens[1] == nil
			twiml = Twilio::TwiML::Response.new do |r|
				r.Message "No name was given."
			end
		else
			twiml = Twilio::TwiML::Response.new do |r|
				r.Message "#{messageTokens[1]} was removed."
			end
		end
	when "-b"
		if messageTokens[2] == nil 
			twiml = Twilio::TwiML::Response.new do |r|
				r.Message "The ball request was not formatted properly."
			end
		else
			twiml = Twilio::TwiML::Response.new do |r|
				r.Message "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
			end
		end
	when "-h"
		twiml = Twilio::TwiML::Response.new do |r|
			r.Message "Valid Inputs:\n\tAdd Baller\n\t-a <name>\n\tRemove Baller\n\t-r <name>\n\tBall Request\n\t-b <location> <time>"
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


