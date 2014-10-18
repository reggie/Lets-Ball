Let's Ball
==========

Let's Ball is a Twillio powered web app that automates the hassle of setting up a group meeting to play basketball.

Once the number associated with the group is known, the user can text in the commands to create, update, or delete ball requests or users.

The supported commands include:


Add Baller 
----------
```sh
 -a <name>
```
Adds users with name <name> to the database (allows spaces in name)
 
 
Update Baller 
-------------
```sh
 -un <name>
```
Changes the name of the user in the database that is associated with the phone number of the texter. (allows spaces in name)
 
Remove Baller 
-------------
```sh
 -r
```
Removes the user associated with the phone number of the texter from the database.

List Ballers 
------------
```sh
 -l
```
Returns a list of all of the users currently in the database.

Ball Request
------------
```sh
 -b <location> <time>
```
Creates a ball event for the <time> at the <location> and notifies all of the users in the database via text. Users can reply to this notification with "-y" to confirm attendance or "-n" to decline and opt out of updates. (location allows spaces, time is an integer)

Update Ball Request 
-------------------
```sh
 -ub <location> <time>
```
Allows the creator of the currently live ball request to update its time and/or location. All users will be notified of the change via text. (location allows spaces, time is an integer)

Remove Ball Request
-------------------
```sh
 -rb
```
Allows the creator of the currently live ball request to delete it, notifying all other users via text.

List Ball Events
----------------
```sh
 -lb
```
Lists the current live ball events. (currently only supports one live event in version 1)

List Confirmed Ballers
----------------------
```sh
 -c
```
Returns all of the users that confirmed attendence for the current ball event.
