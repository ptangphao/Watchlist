# Stock Market Watchlist
# A simple watchlist for tracking publicly traded securities. 
# Description: This ruby program allows you to create a watchlist for tracking publicly traded securities.
# Real time data is provided thanks to Alpha Vantage (http://www.alphavantage.co/)

require 'sqlite3'
require 'net/http'
require 'json'
require_relative 'watchlist_methods'


db = create_database #create database
startup_messages #display startup messages
username = gets.chomp
setup(db,username) #setup initial database and usertable

position = navigate #set initial navigation action
while position != '0'
	case position
	when '1' #View watchlist
		view_positions(db,username)
	when '2' #Add a symbol to watchlist
		open_position(db,username)
	when '3' #Remove a symbol from the watchlist
		close_position(db,username)
	end 
	position = navigate
end 

exit_message #display exit messages
