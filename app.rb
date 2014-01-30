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
events = db.create_collection('Events')
auth_token = ENV['AUTH_TOKEN']
sid = ENV['SID']
client = Twilio::REST::Client.new sid, auth_token

post '/sms' do
	#Stores the text as tokens split by spaces
	messageTokens = params[:Body].split
	number = params[:From]
	message = ""
	date = DateTime.now
	date = date.strftime("%m/%d/%y")
	exists = false
	empty = true

	#Checks if the number exsts in the database already
	if ballers.find({"number" => number}).count != 0
		exists = true
	end	

	#Checks if the events database is empty
	if events.find().count != 0
		empty = false
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
				ballers.insert({"number" => number, "name" => messageTokens[1], "balling" => "-"})
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
			ballers.update({"number" => number}, { "$set" => {"name" => messageTokens[1]} })
			#ballers.update({"number" => number}, {"number" => number, "name" => messageTokens[1], "balling" => "n"})
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
			if !empty
				if events.find({"date" => date}).to_a[0]["date"] == date
					message = "There is already a balling request for today."
				else
					events.remove
 					events.insert({"location" => messageTokens[1], "time" => messageTokens[2], "creator" => number, "date" => date})
				end
			else
				events.insert({"location" => messageTokens[1], "time" => messageTokens[2], "creator" => number, "date" => date})
			end
			name = ballers.find({"number" => number}).to_a[0]["name"]
			ballers.find().each do |doc| 
				if doc['number'] != number
					text = client.account.messages.create(
						:body => "#{name} wants to play basketball at #{messageTokens[1]} at #{messageTokens[2]} o'clock.",
						:to => doc['number'],
						:from => number)
				end
			end
			if message.empty?
				ballers.update({}, { "$set" => {"balling" => "-"} })	
				message = "Ball request: #{messageTokens[1]} at #{messageTokens[2]} - created."
			end
		end
	when "-ub"
		if messageTokens[2] == nil
			message = "The update request was not formatted properly"
		else
			if empty 
				message = "There is no active ball request"
			else 
				if events.find({"creator" => number}).count != 0
					events.update({"creator" => number}, {"location" => messageTokens[1], "time" => messageTokens[2]})
					message = "The event was updated."
					ballers.find().each do |doc|
						if doc['number'] != number
							text = client.account.messages.create(
								:body => "The event was update to: #{messageTokens[1]} at #{messageTokens[2]}",
								:to => doc['number'],
								:from => number)
						end
					end
				else
					message = "You are not the creator of the ball request."
				end
			end
		end
	when "-y"
		if !empty
			ballers.update({"number" => number}, {"balling" => "y"})
			message = "Response stored."
		else 
			message = "There is no request active right now."
		end
	when "-n"
		if !empty
			ballers.update({"number" => number}, {"balling" => "n"})
			message = "Response"
		else
			message = "There is no ball request active right now."
		end
	when "-c"
		ballers.find({"balling" => "y"}).each do |doc|
			message << doc['name'] + "\n"	
		end
		if message.empty?
			message = "No ballers have confirmed attendence yet."
		else
			message << "\r"
		end
	when "-C"
		ballers.remove
		events.remove
	when "-h"	#Ask for help 
		message = "Valid Inputs:\n" 					 +
							"\tAdd Baller\n"   					 +
							"\t-a <name>\n"   					 +
							"\tUpdate Name\n"						 +
							"\t-un <name>"							 +
							"\tRemove Baller\n"	 				 +
							"\t-r <name>\n"    					 +
							"\tList all Ballers\n"       +
							"\t-l\n"							       +
							"\tBall Request\n"		       +
							"\t-b <location> <time>\n"   +
							"\tList confirmed Ballers\n" +
							"\t-c\n"
	when "-T"
		x = 5
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
