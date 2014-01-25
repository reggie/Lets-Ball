require 'rubygems'
require 'twilio-ruby'
require 'mongo'	
require 'uri'
require 'sinatra'

def get_connection
	return @db_connection if @db_connection
	db = URI.parse(ENV['MONGOHQ_URL'])
	db_name = db.path.gsub(/^\//, '')
	@db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
	@db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
	return	@db_connection
end

db = get_connection
ballers = db.collection("Ballers")

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
			if (ballers.find({"number" : params[:From]}).limit(1).size() > 0)
				message = "You are already in the database"
			else
				message = "#{messageTokens[1]} was added."
			end
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
	when "-T"
		message = "Collections\n" +
							"===========\n" +
							"#{db.collection_names}"
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
