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
    m.reply "Hello, #{m.user.nick}. Currently you can ask me: 'latest program', 'user {username}'."
  end

  on :message, /\bhacker_bot\b/ do |m|
    m.reply "Hello, #{m.user.nick}. Currently you can ask me: 'latest program', 'user {username}'."
  end

  on :message, /^user (.+)/ do |m, username|
    user = username
    profile = Nokogiri::HTML(open("https://hackerone.com/#{user}"))

    is_program = profile.css(".report-vulnerability").count

    if is_program == 0
      amount  = profile.css(".profile-stats-amount").first.inner_html
      targets = profile.css(".profile-stats-amount").last.inner_html
      link    = "https://hackerone.com/" + user
      m.reply "#{user} has #{amount} bugs found and #{targets} hacked targets (#{link})."
    else
      m.reply "That is not a valid user."
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
