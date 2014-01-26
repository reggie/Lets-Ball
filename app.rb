require 'rubygems'
require 'twilio-ruby'
require 'mongo'	
require 'uri'
require 'sinatra'
require 'date'

def get_connection
	return @db_connection if @db_connection
	db = URI.parse(ENV['MONGOHQ_URL'])
	db_name = db.path.gsub(/^\//, '')
	@db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
	@db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
	return	@db_connection
end

db = get_connection
ballers = db.create_collection('Ballers')
auth_token = ENV['AUTH_TOKEN']
sid = ENV['SID']
client = Twilio::REST::Client.new sid, auth_token

post '/sms' do
	#Stores the text as tokens split by spaces
	messageTokens = params[:Body].split
	number = params[:From]
	message = ""
	exists = false

	#Checks if the number exsts in the database already
	if ballers.find({"number" => number}).count != 0
		exists = true
	end	
		
	#Cases for different options
	case messageTokens[0]
	when "-a"	#Add yourself to the database
		if messageTokens[1] == nil
			message = "No name was given."
		else
			if exists
				message = "You are already in the database."
			else
				ballers.insert({"number" => number, "name" => messageTokens[1], "Balling" => "N"})
				message = "#{messageTokens[1]} was added."
			end
		end
	when "-r" #Remove youself from the database
		if exists
			ballers.remove({"number"=> number})
			message = "You were removed from the database."
		else
			message = "You are not in the database."
		end
	when "-un"
		if exists
			ballers.update({"number" => number}, {"name" => messageTokens[1]})
			message = "You name has been updated to #{messageTokens[1]}."
		else
			message = "You are not in the database."
		end
	when "-l"
		ballers.find.each do |doc|
			message << doc['name'] + "\n"
		end	
		if message.empty?
			message = "The database is currently empty."
		else	
			message << "\r"
		end
	when "-b"	#Send out a ball request
		if messageTokens[2] == nil 
			message = "The ball request was not formatted properly."
		else
			message = "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
		end
	when "-h"	#Ask for help 
		message = "Valid Inputs:\n" 		 +
							"\tAdd Baller\n"   		 +
							"\t-a <name>\n"   		 +
							"\tUpdate Name\n"			 +
							"\t-un <name>"				 +
							"\tRemove Baller\n"	 	 +
							"\t-r <name>\n"    		 +
							"\tList all Ballers\n" +
							"\t-l\n"							 +
							"\tBall Request\n"		 +
							"\t-b <location> <time>"
	when "-T"
		sms = client.account.messages.get(params[:MessageSid])
		message = "#{sms.date_sent} - "	
		message << DateTime.now
	else	#Default case to alert improper usage
		message = "Invalid input sent. Text -h for help."
	end
	
	#Sends text response
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message message.to_s
	end
	twiml.text
end

post '/call' do
	#Makes app hangup if called
	twiml = Twilio::TwiML::Response.new do |r|
		r.Reject
	end
	twiml.text
end

get '/' do
	"Twilio Time"
end
