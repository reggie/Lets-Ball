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
	return @db_connection
end

configure do
	#The monogo connection
	$db = get_connection
	baller = $db.create_collection('Ballers')
	events = $db.create_collection('Events')
	#The Twilio client connection
	auth_token = ENV['AUTH_TOKEN']
	sid = ENV['SID']
	$client = Twilio::REST::Client.new sid, auth_token
end

def text message, sender
	$db.ballers.find().each do |doc| 
		if doc['number'] != sender
			text = $client.account.messages.create(
				:body => message,
				:to => doc['number'],
				:from => "+12014686232")
		end
	end
end

def add tokens, found, number, empty
	if tokens[1] == nil
		return "No name was given."
	else
		if found
			return "You are already in the database."
		else
			$db.ballers.insert({"number" => number, "name" => tokens[1], "balling" => "-"})
			if empty
				return "#{tokens[1]} was added."
			else
				events = listEvents()
				return "#{tokens[1]} was added.\nThere is an active event: #{events}.Text \"-y\" to confirm, \"-n\" to deny. "	
			end
		end
	end
end

def remove found, number
	if found
		$db.ballers.remove({"number"=> number})
		return "You were removed from the database."
	else
		return "You are not in the database."
	end
end

def updateName tokens, found, number
	if found
		$db.ballers.update({"number" => number}, { "$set" => {"name" => tokens[1]} })
		return "You name has been updated to #{tokens[1]}."
	else
		return "You are not in the database."
	end
end

def listBallers
	result = ""
	$db.ballers.find.each do |doc|
		result << doc['name'] + "\n"
	end	
	if result.empty?
		return "The database is currently empty."
	else	
		result << "\r"
		return result
	end
end

def listEvents
	result = ""
	$db.events.find.each do |doc|
		result << doc['location'] + " at " + doc['time'] +"\n"
	end	
	if result.empty?
		return "The database is currently empty."
	else	
		result << "\r"
		return result
	end
end

def listConfirmed
	result = ""
	$db.ballers.find({"balling" => "y"}).each do |doc|
		result << doc['name'] + "\n"	
	end
	if result.empty?
		return "No ballers have confirmed attendence yet."
	else
		result << "\r"
		return result
	end
end

def flatten tokens, last
	result = tokens[1]
	for n in 2...last
		result << tokens[n]
	end
end

def makeEvent tokens, date, number, empty, name
	if tokens[2] == nil 
		return "The ball request was not formatted properly."
	elsif !tokens.last.is_a? Integer
		 return "The time token was not a number."
	else
		location = flatten(tokens, tokens.length - 1)
		if !empty
			if $db.events.find({"date" => date}).to_a[0]["date"] == date
				return "There is already a balling request for today."
			else
				$db.events.remove
 				$db.events.insert({"location" => location, "time" => tokens.last, "creator" => number, "date" => date})
			end
		else
			$db.events.insert({"location" => location, "time" => tokens.last, "creator" => number, "date" => date})
		end
		if message.empty?
			name = $db.ballers.find({"number" => number}).to_a[0]["name"]
			message = "#{name} wants to play basketball at #{location} at #{tokens.last} o'clock.\nText \"-y\" to confirm or \"-n\" to deny."
			text(message, number)
			$db.ballers.update({}, { "$set" => {"balling" => "-"} })
			$db.ballers.update({"number" => number}, {"$set" => {"balling" => "y"} })
			return "Ball request: #{location} at #{tokens.last} - created."
		end
	end
end

def updateEvent tokens, number, empty
	if tokens[2] == nil
		return "The update request was not formatted properly"
	else
		if empty 
			return "There is no active ball request"
		else 
			if $db.events.find({"creator" => number}).count != 0
				$db.events.update({"creator" => number}, {"$set" => {"location" => tokens[1], "time" => tokens[2]} })
				message = "The event was updated to: #{tokens[1]} at #{tokens[2]}"
				text(message, number)
				return "The event was updated."
			else
				return "You are not the creator of the ball request."
			end
		end
	end
end

def removeEvent number, empty
	if empty
		return "There is no active ball request"
	else
		if $db.events.find({"creator" => number}).count != 0
			$db.events.remove
			name = $db.ballers.find({"number" => number}).to_a[0]["name"]
			message = "The balling event has been cancelled by #{name}."
			text(message, number)
			return "The request has been cancelled."
		else 
			return "You are not the creator of the event."
		end
	end
end

def respond type, empty
	if !empty
		$db.ballers.update({"number" => number}, {"$set" => {"balling" => type} })
		return "Response stored."
	else 
		return "There is no request active right now."
	end
end

def help
	return "Valid Inputs:\n"						+
					"\tAdd Baller\n"						+
					"\t-a <name>\n"							+
					"\tUpdate Name\n"						+
					"\t-un <name>\n"						+
					"\tRemove Baller\n"					+
					"\t-r <name>\n"							+
					"\tList all Ballers\n"			+
					"\t-l\n"										+
					"\tBall Request\n"					+
					"\t-b <location> <time>\n"	+
					"\tUpdate Ball Request\n"		+
					"\t-ub <location> <time>\n"	+
					"\tRemove Ball Request\n"		+
					"\t-rb\n"										+
					"\tList Ball Events\n"			+
					"\t-lb\n"										+
					"\tList confirmed Ballers\n"+
					"\t-c\n"
end

post '/sms' do
	#Stores the text as tokens split by spaces
	messageTokens = params[:Body].split

	#Stores number of texter
	number = params[:From]
	
	#Variable to hold response message
	message = ""

	#Stores date of the text that is being interpretted
	date = DateTime.now
	date = date.strftime("%m/%d/%y")

	#Variables to make note of the capacity of each collection
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
		message = add(messageTokens, exists, number, empty)
	when "-r" #Remove youself from the database
		message = remove(exists, number)
	when "-un"#Update your name in the database
		message = updateName(messageTokens, exists, number)
	when "-l" #List all ballers
		message = listBallers()
	when "-b"	#Send out a ball request
		message = makeEvent(messageTokens, date, number, empty)
	when "-ub"#Update the ball request
		message = updateEvent(messageTokens, number, empty)
	when "-rb"#Remove a ball request
		message = removeEvent(number, empty)
	when "-lb"#List all ball events
		message = listEvents()
	when "-y"	#Confirm attendance
		message = respond("y", empty)	
	when "-n"	#Deny attendance
		message = respond("n", empty)
	when "-c"	#List all confirmed ballers
		message = listConfirmed()
	when "-C"	#Clears both databases (for emergency cases)
		$db.ballers.remove
		$db.events.remove
	when "-h"	#Ask for help 
		message	= help()
	else			#Default case to alert improper usage
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
