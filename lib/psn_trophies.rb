require "nokogiri"
require "net/http"
require "uri"

module PsnTrophies

  class NoUserProfileError < StandardError; end

  class Client

    def get_avatar(profile_id)
      check_profile_id(profile_id)
      body = get_body("http://us.playstation.com/playstation/psn/profiles/#{profile_id}",
                      "http://us.playstation.com/publictrophy/index.htm?onlinename=#{profile_id}")
      doc = Nokogiri::HTML.fragment(body)
      avatar = doc.css("#id-avatar").children[1].to_a[3][1]
    end

    def trophies_count(profile_id)
      check_profile_id(profile_id)
      body = get_body("http://us.playstation.com/playstation/psn/profiles/#{profile_id}",
                      "http://us.playstation.com/publictrophy/index.htm?onlinename=#{profile_id}")
      doc = Nokogiri::HTML.fragment(body)
      level = doc.css("#levelprogress").children.children[1].content.gsub("\r\n","").strip
      total_trophies = doc.css("#totaltrophies").children.children[0].content.gsub("\r\n","").strip
      platinum = doc.css(".podium").children.children[6].content.split(" ")[0]
      gold = doc.css(".podium").children.children[4].content.split(" ")[0]
      silver = silver = doc.css(".podium").children.children[2].content.split(" ")[0]
      bronze = bronze = doc.css(".podium").children.children[0].content.split(" ")[0]
      info = ['level' => level, 'total_trophies' => total_trophies, 'platinum' => platinum, 'gold' => gold,
        'silver' => silver, 'bronze' => bronze]
    end

    def get_cover(game)
      body = get_body("http://us.playstation.com/ps-products/BrowseGames?console=ps3&beginsWith=#{CGI.escape game}", "http://us.playstation.com/ps-products/BrowseGames?console=ps3&beginsWith=#{CGI.escape game}")
      doc = Nokogiri::HTML.fragment(body)
      cover = doc.css(".thumb").first.children[0].children.to_a[0]["src"]
    end

    def trophies(profile_id)
      check_profile_id(profile_id)
      body = get_body("http://us.playstation.com/playstation/psn/profile/#{profile_id}/get_ordered_trophies_data","http://us.playstation.com/publictrophy/index.htm?onlinename=#{profile_id}/trophies")

      games = []
      doc = Nokogiri::HTML.fragment(body)
      doc.css('.slotcontent').each do |container|
        logo = container.at_css('.titlelogo img')["src"]
        title = container.at_css('.gameTitleSortField').content
        progress = container.at_css('.gameProgressSortField').content
        trophies = container.at_css('.gameTrophyCountSortField').content.strip

        games << PlayedGame.new(:image_url => logo, :title => title, :progress => progress, :trophy_count => trophies)
      end
      games
    end

    private

    def check_profile_id(profile_id)
      body = get_body("http://us.playstation.com/playstation/psn/profiles/#{profile_id}",
                      "http://us.playstation.com/publictrophy/index.htm?onlinename=#{profile_id}")
      doc = Nokogiri::HTML(body)
      error_section = doc.at_css('.errorSection')
      unless error_section.nil?
        raise NoUserProfileError.new("No User Profile for #{profile_id}")
      end
    end

    def get_body(uri, referer)
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Host"] = "us.playstation.com"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      request["Accept-Language"] = "en-us,en;q=0.5"
      request["Accept-Charset"] = "ISO-8859-1,utf-8;q=0.7,*;q=0.7"
      request["Connection"] = "keep-alive"
      request["Referer"] = referer

      response = http.request(request)
      response.body
    end

  end
  class PlayedGame
    attr_accessor :image_url, :title, :progress, :trophy_count

    def initialize(attrs = {})
      attrs.each { |attr, value| self.send(:"#{attr}=", value) }
    end
  end

end
