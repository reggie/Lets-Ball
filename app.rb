require 'rubygems'
require 'twilio-ruby'
require 'mongo'
require 'uri'
require 'sinatra'
require 'date'

# Connects to the MongoDB database
def mongo_connection
  # Returns the connection if it is already established
  return $db_connection if $db_connection

  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  $db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)

  unless db.user.nil? || db.password.nil?
    $db_connection.authenticate(db.user, db.password)
  end

  $db_connection
end

# Creates the databases when the app is deployed
configure do
  # The monogo connection
  db = mongo_connection
  $ballers = db.create_collection('Ballers')
  $events = db.create_collection('Events')
  # The Twilio client connection
  auth_token = ENV['AUTH_TOKEN']
  sid = ENV['SID']
  $client = Twilio::REST::Client.new sid, auth_token
end

# Sends the text
def text(message, sender)
  $ballers.find.each do |doc|
    next if doc['number'] == sender
    $client.account.messages.create(
      body: message,
      to: doc['number'],
      from: '+12014686232')
  end
end

# Allows for spaces in name by concatenating multiple array indices
def flatten(tokens)
  tokens.shift
  tokens.join(' ')
end

# Adds baller to the database
def add(tokens, found, number, empty)
  if tokens[1].nil?
    'No name was given.'
  else
    if found
      'You are already in the database.'
    else
      name = flatten(tokens)
      $ballers.insert('number' => number, 'name' => name, 'balling' => '-')
      if empty
        "#{name} was added."
      else
        events = list_events
        "#{name} was added.\nThere is an active event:\n#{events}Text \'-y\' " \
        "to confirm, \'-n\' to deny."
      end
    end
  end
end

# Removes baller from the database
def remove(found, number)
  if found
    $ballers.remove('number' => number)
    'You were removed from the database.'
  else
    'You are not in the database.'
  end
end

# Updates the name of the baller in the database
def update_name(tokens, found, number)
  if found
    $ballers.update({ 'number' => number },
                    { '$set' => { 'name' => tokens[1] } })
    "You name has been updated to #{tokens[1]}."
  else
    'You are not in the database.'
  end
end

# Returns a list of all the ballers in the database
def list_ballers
  result = ''
  $ballers.find.each do |doc|
    result << doc['name'] + "\n"
  end
  if result.empty?
    'The database is currently empty.'
  else
    result
  end
end

# Returns a list of all the events in the database
def list_events
  result = ''
  $events.find.each do |doc|
    result << doc['location'] + ' at ' + doc['time'] + "\n"
  end
  if result.empty?
    'The database is currently empty.'
  else
    result
  end
end

# Returns the list of ballers confirmed to attend the current event
def list_confirmed
  result = ''
  $ballers.find('balling' => 'y').each do |doc|
    result << doc['name'] + "\n"
  end
  if result.empty?
    'No ballers have confirmed attendence yet.'
  else
    result
  end
end

# Creates the ball event
def make_event(tokens, date, number, empty)
  error = 'The ball request was not formatted properly.'
  return error if tokens[2].nil? || tokens.last.to_i == 0

  location = flatten(tokens, tokens.length - 1)
  if !empty
    if $events.find.to_a[0]['date'] == date
      return 'There is already a balling request for today.'
    else
      $events.remove
      $events.insert('location' => location,
                     'time' => tokens.last,
                     'creator' => number,
                     'date' => date)
    end
  else
    $events.insert('location' => location,
                   'time' => tokens.last,
                   'creator' => number,
                   'date' => date)
  end
  name = $ballers.find('number' => number).to_a.first['name']
  message =
    "#{name} wants to play basketball at #{location} at #{tokens.last} " \
    "o'clock.\nText \'-y\' to confirm or \'-n\' to deny."
  text(message, number)
  $ballers.update({}, { '$set' => { 'balling' => '-' } })
  $ballers.update({ 'number' => number }, { '$set' => { 'balling' => 'y' } })
  "Ball request: #{location} at #{tokens.last} - created."
end

# Updates information of a ball event
def update_event(tokens, number, empty)
  error = 'The ball request was not formatted properly.'
  return error if tokens[2].nil? || tokens.last.to_i == 0

  if empty
    'There is no active ball request'
  else
    location = flatten(tokens, tokens.length - 1)
    if $events.find('creator' => number).count != 0
      $events.update({ 'creator' => number },
                     { '$set' =>
                       { 'location' => location, 'time' => tokens.last } })
      message = "The event was updated to: #{location} at #{tokens.last}"
      text(message, number)
      'The event was updated.'
    else
      'You are not the creator of the ball request.'
    end
  end
end

# Removes ball event
def remove_event(number, empty)
  if empty
    'There is no active ball request'
  else
    if $events.find('creator' => number).count != 0
      $events.remove
      name = $ballers.find('number' => number).to_a[0]['name']
      message = "The balling event has been cancelled by #{name}."
      text(message, number)
      'The request has been cancelled.'
    else
      'You are not the creator of the event.'
    end
  end
end

# Tracks response to ball request
def respond(type, empty, number)
  if !empty
    $ballers.update({ 'number' => number }, { '$set' => { 'balling' => type } })
    'Response stored.'
  else
    'There is no request active right now.'
  end
end

# Displays the help menu upon request or impropr input
def help
  "Valid Inputs:\n\tAdd Baller\n\t-a <name>\n" \
  "\tUpdate Name\n"                            \
  "\t-un <name>\n"                             \
  "\tRemove Baller\n"                          \
  "\t-r\n"                                     \
  "\tList all Ballers\n"                       \
  "\t-l\n"                                     \
  "\tBall Request\n"                           \
  "\t-b <location> <time>\n"                   \
  "\tUpdate Ball Request\n"                    \
  "\t-ub <location> <time>\n"                  \
  "\tRemove Ball Request\n"                    \
  "\t-rb\n"                                    \
  "\tList Ball Events\n"                       \
  "\t-lb\n"                                    \
  "\tList confirmed Ballers\n"                 \
  "\t-c\n"
end

post '/sms' do
  # Stores the text as tokens split by spaces
  message_tokens = params[:Body].split

  # Stores number of texter
  number = params[:From]

  # Variable to hold response message
  message = ''

  # Stores date of the text that is being interpretted
  date = DateTime.now
  date = date.strftime('%m/%d/%y')

  # Variables to make note of the capacity of each collection
  exists = false
  empty = true

  # Checks if the number exsts in the database already
  exists = true if $ballers.find('number' => number).count != 0

  # Checks if the events database is empty
  empty = false if $events.find.count != 0

  # Cases for different options
  case message_tokens[0]
  when '-a'  # Add yourself to the database
    message = add(message_tokens, exists, number, empty)
  when '-r'  # Remove youself from the database
    message = remove(exists, number)
  when '-un' # Update your name in the database
    message = update_name(message_tokens, exists, number)
  when '-l'  # List all ballers
    message = list_ballers
  when '-b'  # Send out a ball request
    message = make_event(message_tokens, date, number, empty)
  when '-ub' # Update the ball request
    message = update_event(message_tokens, number, empty)
  when '-rb' # Remove a ball request
    message = remove_event(number, empty)
  when '-lb' # List all ball events
    message = list_events
  when '-y'  # Confirm attendance
    message = respond('y', empty, number)
  when '-n'  # Deny attendance
    message = respond('n', empty, number)
  when '-c'  # List all confirmed ballers
    message = list_confirmed
  when '-C'  # Clears both databases (for emergency cases)
    $ballers.remove
    $events.remove
  when '-h'  # Ask for help
    message  = help
  else       # Default case to alert improper usage
    message = 'Invalid input sent. Text -h for help.'
  end

  # Sends text response
  twiml = Twilio::TwiML::Response.new do |r|
    r.Message message.to_s
  end
  twiml.text
end

post '/call' do
  # Makes app hangup if called
  Twilio::TwiML::Response.new do |r|
    r.Play '#{request.url.gsub(/call/, '')}test.mp3', loop: 1
  end.text
end
