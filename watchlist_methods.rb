# Create a database

def create_database
	database = SQLite3::Database.new("watchlist.db")
	database.results_as_hash = true
	return database
end 

# Creates the user table within the database

def create_user_table(database)
	create_user_table_cmd = <<-SQL 
	CREATE TABLE IF NOT EXISTS users(
		id INTEGER PRIMARY KEY,
		name VARCHAR(255) UNIQUE
	)
SQL
	database.execute(create_user_table_cmd)
end 

# Creates the portfolio table within the databsae

def create_portfolio_table(database)
	create_portfolio_table_cmd = <<-SQL 
	CREATE TABLE IF NOT EXISTS users(
		id INTEGER PRIMARY KEY,
		user_id int,
		watch_id int,
		FOREIGN KEY (user_id) REFERENCES users(id)
		FOREIGN KEY (watch_id) REFERENCES watchlist(id)
	)
SQL
	database.execute(create_user_table_cmd)
end 

# Creates the watchlist within the database

def create_watch_table(database)
	create_watch_table_cmd = <<-SQL 
	CREATE TABLE IF NOT EXISTS watchlist(
		id INTEGER PRIMARY KEY,
		ticker VARCHAR(6),
		initial_price FLOAT(2),
		current_price FLOAT(2),
		user_id int,
		FOREIGN KEY (user_id) REFERENCES users(id)
	)
SQL
	database.execute(create_watch_table_cmd)
end 

#Creates a new user within the users table

def create_new_user(database, username)
	database.execute("INSERT INTO users (name) VALUES ( ? )",[username])
end 

# Checks whether the user already exists or not - not necessary if using UNIQUE constraint on name and exception handling

def check_duplicate_user(database, username)
	check_command = "Select * from users where name = '#{username}'"
	if database.execute(check_command).length > 0
		return true
	else 
		return false 
	end 
end 

# Pulls current value from JSON for a ticker

def livequote(ticker)
	function = 'TIME_SERIES_INTRADAY'
	symbol = ticker
	interval = '1min' 
	apikey = '4528' #provided at registration
	url = "http://www.alphavantage.co/query?function=#{function}&symbol=#{symbol}&interval=#{interval}&apikey=#{apikey}"
	uri = URI(url)
	response = Net::HTTP.get(uri)
	info = JSON.parse(response)
	return info.values[1].values[0].values[3].to_f.round(2)
end 

# Checks if ticker is valid

def tickercheck(ticker)
	function = 'TIME_SERIES_INTRADAY'
	symbol = ticker
	interval = '1min' 
	apikey = '4528' #provided at registration
	url = "http://www.alphavantage.co/query?function=#{function}&symbol=#{symbol}&interval=#{interval}&apikey=#{apikey}"
	begin
		uri = URI(url) 
		response = Net::HTTP.get(uri)
		if JSON.parse(response).keys[0] == "Error Message"
			return false
		else 
			return true
		end
	rescue
		return false
	end 
end

# Creates a new position in the watchlist

def open_position(database,username)
	puts "What ticker would you like to add to your watchlist"
	ticker = gets.chomp.upcase
	if position_exists(database, ticker, username) 
		puts "This position already exists."
	elsif tickercheck(ticker) == true 
			initial_price = livequote(ticker)
			current_price = initial_price
			current_user_id = database.execute("Select id from users where name = '#{username}'")[0]["id"]
			database.execute('INSERT INTO watchlist (ticker,initial_price,current_price,user_id) VALUES ( ?, ?, ?, ?)',[ticker, initial_price, current_price, current_user_id])
	else
		puts "That is not a valid ticker."
	end
end 

#Updates watchlist's current_values

def update_position(database, user_id)
	tickers_to_update = database.execute("Select ticker from watchlist where user_id = #{user_id}").map!{ |a| a[0] }
	tickers_to_update.each do |i|
		current_price = livequote(i)
		ticker = i
		update_command = "UPDATE watchlist SET current_price = '#{current_price}' WHERE ticker = '#{ticker}'"
		database.execute(update_command)
	end 
end

#Deletes a position in the watchlist

def close_position(database, username)
	current_user_id = database.execute("Select id from users where name = '#{username}'")[0]["id"]
	puts "What ticker would you like to delete from your watchlist?"
	ticker = gets.chomp.upcase
	if position_exists(database, ticker, username)
		database.execute("DELETE FROM watchlist WHERE ticker = '#{ticker}'")
	else 
		puts "This position does not exist."
	end 
end

#Checks if the ticker is in the user's watchlist

def position_exists(database, ticker, username)
	current_user_id = database.execute("Select id from users where name = '#{username}'")[0]["id"].to_s
	check_command = "Select id from watchlist where ticker = '#{ticker}' and user_id = #{current_user_id}"
	if database.execute(check_command).length > 0
		return true
	else 
		return false 
	end
end 

#Shows all of a user's positions in a watchlist
def view_positions(database, username)
	puts ["Ticker  Initial Price  Current Price"]
	current_user_id = database.execute("Select id from users where name = '#{username}'")[0]["id"].to_s
	view_command = "Select ticker, initial_price, current_price from watchlist where user_id = #{current_user_id}"
	update_position(database, current_user_id) if database.execute(view_command).length > 0 
	hash_list = database.execute(view_command)

	hash_list.each do |i|
		this_ticker = i[0]
		this_initial_price = i[1].to_s
		#ALIGN PRICES FOR PRESENTATION
		while this_ticker.length < 6
			this_ticker = this_ticker+' ' 
		end
		while this_initial_price.length < 6
			this_initial_price = ' '+this_initial_price 
		end 
		this_current_price = i[2].to_s
		while this_current_price.length < 6
			this_current_price = ' '+this_current_price 
		end
		puts "#{this_ticker}     #{this_initial_price}         #{this_current_price}"
	end 
end 


# Interface

def startup_messages
	puts "Welcome to your watchlist!"
	puts "Created on April 6th, 2017"
	puts "http://www.github.com/ptangphao"
	puts "Please enter your username:"
end 

def setup(db, username)
	create_user_table(db)
	create_watch_table(db)
	begin
	create_new_user(db, username) # if check_duplicate_user(db, username) == false # NOT NECESSARY SINCE USING EXCEPTION HANDLING
	rescue 
	puts "Welcome back to your watchlist."
	end  
end 

def navigate
	nav = nil
	while navigation_check(nav) == false
		puts "Would you like to [1] View your watchlist [2] Add a symbol to your watchlist [3] Remove a symbol from your watchlist [0] Exit from your watchlist."
		nav = gets.chomp
		puts "Invalid input, please enter a new input" if navigation_check(nav) == false
	end
	return nav
end

def navigation_check(input)
	options = ['1','2','3','0']
	return options.include?(input) 
end

def exit_message
	puts "Closing the watchlist..."
	puts "Thank you for using the watchlist!"
end