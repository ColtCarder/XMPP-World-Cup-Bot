require 'blather/client/dsl'
require 'rest_client'
require 'json'
require 'time'
require_relative 'inc.rb'

class GoalBot
	extend Blather::DSL
	def self.run
        inc = Inc.new
        username = inc.username()
        password = inc.password()
        setup username,password 
		print "Connected to #{jid.stripped}\nGOAL Bot Initialized\n"
		EM.run { client.run }
	end

    def get_time(time)
    end


    users = []
	message :chat?, :body => "!goal" do |m|
        unless users.include?(m.from.to_s)
        say m.from, "You've been added to the event watcher!"
        users.push(m.from.to_s)
        threadName = m.from.to_s
        threadName = Thread.new do
            threadUser = m.from.to_s
            home_cache = ''
            away_cache = ''
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
                   say threadUser, "No current game. Try again later."
                    users.delete(threadUser)
                    puts "Thread stopped for #{threadUser}\n"
                    Thread.stop
                    break
                end
                
                response = JSON.parse(response)
                if home_cache != response.first["home_team_events"] or start == 0
                    if start == 0
                    home_cache = response.first["home_team_events"]
                    home_cache.each do |x|
                      say threadUser, "#{response.first["home_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | Time: #{x["time"]}"
                      sleep(1)
                      puts "Sending home to #{threadUser}"
                    end
                    start = 1
                    else
                      home_cache = response.first["home_team_events"]
                      home_cache.each do |x|
                          finalMessage = "#{response.first["home_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | Time: #{x["time"]}"
                      end
                      puts "Sending #{finalMessage} to #{threadUser}"
                      say threadUser, "#{finalMessage}"
                    end
                end
                if away_cache != response.first["away_team_events"] or start2 == 0
                    if start2 == 0
                    away_cache = response.first["away_team_events"]
                    away_cache.each do |x|
                      say threadUser, "#{response.first["away_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | Time: #{x["time"]}"
                      sleep(1)
                      puts "Sending away to #{threadUser}"
                    end
                    start2 = 1
                    else
                       away_cache = response.first["away_team_events"]
                       away_cache.each do |x|
                        finalMessage2 = "#{response.first["away_team"]["country"]}| Event: #{x["type_of_event"]} | Player: #{x["player"]} | time: #{x["time"]}"
                       end
                       puts "Sending #{finalMessage2} to #{threadUser}"
                       say threadUser, "#{finalMessage2}"
                    end
                end

            end
        end
    #    threadName.join
        end
	end

    message :chat?, :body => "!today" do |m|
        puts "#{m.from} asked for Today's Matches"
        response = RestClient.get 'http://worldcup.sfg.io/matches/today', {:accept => :json}
        response = JSON.parse(response)
        response.each do |x|
            parse_time = Time.parse(x["datetime"]) + Time.zone_offset('EDT')
            time = parse_time.strftime("%I:%M %p")
            match = "#{x["home_team"]["country"]} (#{x["home_team"]["code"]}) vs. #{x["away_team"]["country"]} (#{x["away_team"]["code"]}) Match Status: #{x["status"]} | Match Time: #{time}"
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
        begin
        response = RestClient.get "http://worldcup.sfg.io/matches/country?fifa_code=#{var}", {:accept => :json}
        response = JSON.parse(response)
        response.each do |x|
            parse_time = Time.parse(x["datetime"]) + Time.zone_offset('EDT')
            time = parse_time.strftime("%A %B %e, %I:%M %p")
            match = "#{x["home_team"]["country"]} (#{x["home_team"]["code"]}) vs. #{x["away_team"]["country"]} (#{x["away_team"]["code"]}) Match Status: #{x["status"]} | Match Time: #{time}"
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
        puts "Sending commands to #{m.from}"
        say m.from, "==COMMANDS=="
        sleep(1)
        say m.from, "!today - Return todays matches/scores"
        sleep(1)
        say m.from, "!team XXX - Example !team USA return the scores for a particular team"
        sleep(1)
        say m.from, "!goal - Get live events from the current game"
        sleep(1)
        say m.from, "!group X - Get group rankings and information"
        sleep(1)
        say m.from, "!score - Get current score if there is a game in progress"
        sleep(1)
        say m.from, "==========="
        sleep(1)
    end

    message :chat?, :body => /(!group)( )\b([a-hA-H])\b/ do |m|
       var = m.body.to_s.split(" ")[1].upcase
       response = RestClient.get "http://worldcup.sfg.io/teams/group_results", {:accept => :json}
       response = JSON.parse(response)
       counter = 1
       puts "Sending group #{var} stats to #{m.from}"
       response.each do |x|
           if x['group']['letter'] == var
               x['group']['teams'].each do |y|
                    say m.from, "Rank ##{counter}) #{y['team']['country']} (#{y['team']['fifa_code']}) | Points: #{y['team']['points']} Goal Difference #{y['team']['goal_differential']}"
                    sleep(1)
                    counter = counter + 1
               end
           end
       end
    end
    message :chat?, :body => "!score" do |m|
        response = RestClient.get 'http://worldcup.sfg.io/matches/current', {:accept => :json}
        if response == "[]"
           puts "#{m.from.to_s} asked for the score, but there is no current game."
           say m.from, "No current game. Try again later."
        else
        response = JSON.parse(response)
        say m.from, "#{response.first["home_team"]["country"]}: #{response.first["home_team"]["goals"]} vs. #{response.first["away_team"]["country"]}: #{response.first["away_team"]["goals"]}"
        puts "Sending score to #{m.from.to_s}"
        end
        sleep(1)
    end
	disconnected { client.connect }
end

trap(:TERM) { EM.stop }
trap(:INT) { EM.stop }
GoalBot.run
