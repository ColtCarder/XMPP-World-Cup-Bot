require 'blather/client/dsl'
require 'rest_client'
require 'json'
require 'time'

class GoalBot
	 extend Blather::DSL
	def self.run
        setup 'username', 'password'
		print "Connected to #{jid.stripped}\nThis is the GOAL Bot\n"
		EM.run { client.run }
	end

    users = []
    home_cache = ''
    away_cache = ''
	message :chat?, :body => "!goal" do |m|
        unless users.include?(m.from.to_s)
        say m.from, "You've been added to the event watcher!"
        users.push(m.from.to_s)
        threadName = m.from.to_s
        threadName = Thread.new do
            threadUser = m.from.to_s
            print "Thread started for #{threadUser}\n"
            start = 0
            start2 = 0
            loop do
                finalMessage = ''
                finalMessage2 = ''
                threadUser = m.from.to_s
                sleep(3)
                response = RestClient.get 'http://worldcup.sfg.io/matches/current', {:accept => :json}
                if response == "[]"
                    say threadUser, "No current game."
                    users.delete(threadUser)
                    break

                end
                
                response = JSON.parse(response)
                if home_cache != response.first["home_team_events"] or start == 0
                    if start == 0
                    home_cache = response.first["home_team_events"]
                    home_cache.each do |x|
                      say threadUser, "#{response.first["home_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | Time: #{x["time"]}"
                      puts "Sending home to #{threadUser}"
                    end
                    start = 1
                    else
                      home_cache.each do |x|
                          finalMessage = "#{response.first["home_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | Time: #{x["time"]}"
                      end
                      say threadUser, "#{finalMessage}"
                    end
                end
                if away_cache != response.first["away_team_events"] or start2 == 0
                    if start2 == 0
                    away_cache = response.first["away_team_events"]
                    away_cache.each do |x|
                      say threadUser, "#{response.first["away_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | Time: #{x["time"]}"
                      puts "Sending away to #{threadUser}"
                    end
                    start2 = 1
                    else
                       away_cache.each do |x|
                        finalMessage2 = "#{response.first["away_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | time: #{x["time"]}"
                       end
                       say threadUser, "#{finalMessage2}"
                    end
                end

            end
        end
        threadName.join
        end
	end

    message :chat?, :body => "!today" do |m|
        response = RestClient.get 'http://worldcup.sfg.io/matches/today', {:accept => :json}
        response = JSON.parse(response)
        response.each do |x|
            match = "#{x["home_team"]["country"]} (#{x["home_team"]["code"]}) vs. #{x["away_team"]["country"]} (#{x["away_team"]["code"]}) Match Status: #{x["status"]}"
            say m.from, match
            sleep(1)
            if x["status"] == "completed"
                score = "Winner: #{x["winner"]} | Final Score: #{x["home_team"]["code"]}: #{x["home_team"]["goals"]} vs #{x["away_team"]["code"]}: #{x["away_team"]["goals"]}"
                say m.from, score
                sleep(1)
            end
        end
    end

    message :chat?, :body => /(!team)( )\b([a-zA-Z][a-zA-Z][a-zA-Z])\b/ do |m|
        var = m.body.to_s.split(" ")[1].upcase
        puts var
        begin
        response = RestClient.get "http://worldcup.sfg.io/matches/country?fifa_code=#{var}", {:accept => :json}
        response = JSON.parse(response)
        response.each do |x|
            match = "#{x["home_team"]["country"]} (#{x["home_team"]["code"]}) vs. #{x["away_team"]["country"]} (#{x["away_team"]["code"]}) Match Status: #{x["status"]}"
            say m.from, match
            puts "Saying #{match}"
            sleep(1)
            if x["status"] == "completed"
                score = "Winner: #{x["winner"]} | Final Score: #{x["home_team"]["code"]}: #{x["home_team"]["goals"]} vs #{x["away_team"]["code"]}: #{x["away_team"]["goals"]}"
                say m.from, score
                sleep(1)
                puts "Saying #{score}"
            end 
        end
        rescue Exception => e
        puts e.message
        say m.from, "Not a valid request."
        end
    end
    message :chat?, :body => "!help" do |m|
        puts m.from
        say m.from, "==COMMANDS=="
        sleep(1)
        say m.from, "!today - Return todays matches/scores"
        sleep(1)
        say m.from, "!team XXX - Example !team USA return the scores for a particular team"
        sleep(1)
        say m.from, "!goal - Get live events from the current game"
        sleep(1)
        say m.from, "==========="
    end
    message :chat?, :body do |m|
    end
	disconnected { client.connect }
end

trap(:TERM) { EM.stop }
trap(:INT) { EM.stop }
GoalBot.run
