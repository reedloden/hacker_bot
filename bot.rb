require 'cinch'
require 'nokogiri'
require 'open-uri'
require 'openssl'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = ["#hackerone"]
    c.nick = "hacker_bot"
  end

  on :message, /\bhello\b/ do |m|
    m.reply "Hello, #{m.user.nick}. Currently you can ask me: 'latest program', 'whois {username/teamname}'."
  end

  on :message, /\bhacker_bot\b/ do |m|
    m.reply "Hello, #{m.user.nick}. Currently you can ask me: 'latest program', 'whois {username/teamname}'."
  end

  on :message, /^whois (.+)$/ do |m, handle|
    profile = Nokogiri::HTML(open("https://hackerone.com/#{handle}"))

    is_team = profile.css(".report-vulnerability").count
    is_user = profile.search("[text()*='Targets hacked']").count

    data = profile.css(".profile-stats-amount")
    link    = "https://hackerone.com/" + handle

    if is_team > 0
      does_bounties = data.count >= 3
      base_bounty = does_bounties ? data.first.inner_html : '$0'
      participants = does_bounties ? data[1].inner_html : data[0].inner_html
      bugs_closed = data.last.inner_html

      m.reply "Team #{handle} offers a #{base_bounty} minimum bounty, closed out #{bugs_closed} "\
              "bugs and thanked #{participants} unique hackers (#{link})."
    elsif is_user > 0
      amount  = data.first.inner_html
      targets = data.last.inner_html

      m.reply "#{handle} found #{amount} bugs and hacked #{targets} unique targets (#{link})."
    else
      m.reply "That is not a valid profile."
    end
  end

  on :message, "latest program" do |m|
    programs = Nokogiri::HTML(open("https://hackerone.com/programs", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
    name = programs.css(".new-hacktivity-profile-bio-name").first.inner_html
    link = "https://hackerone.com" + programs.css(".new-hacktivity-profile-bio-name").first["href"]
    m.reply "The latest program is: #{name} (#{link})"
  end

end

bot.start
