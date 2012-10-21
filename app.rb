require 'anemone'
require 'json'
require 'open-uri'
require 'sinatra'

get '/crawl?*' do
  if params[:url].nil?
    raise "You must supply a url to crawl."
  else
    links = Hash.new
    url = URI::encode(params[:url])
    begin
      logger.info ">>> Crawling #{url}"

      Anemone.crawl(url, {  :accept_cookies => false,
                            :obey_robots_txt => true,
                            :discard_page_details => true,
                            :html_only_bodies => true,
                            :user_agent => Constants::ANEMONE_USER_AGENT,
                            :max_queue_size => Constants::ANEMONE_MAX_QUEUE_SIZE,
                            :read_timeout => Constants::ANEMONE_READ_TIMEOUT,
                            :threads => Constants::ANEMONE_THREADS }) do |anemone|

        skip_links_regexp = Constants::ANEMONE_SKIP_LINKS        
        anemone.skip_links_like(skip_links_regexp)  

        anemone.on_every_page do |page|
          response_code = page.code
          logger.info ">>>> Response code: (#{response_code}) :: (#{page.url.to_s})"          
          links[page.url.to_s] = { 
            :page_headers => page.headers
          }

        anemone.after_crawl { 
          links
        }
        end      
      end
      logger.info "<<< Finished crawling #{url}"
    rescue => e
      logger.info "!!! Caught exception while crawling #{url}: #{e.inspect} #{e.backtrace}"
      raise "!!! Caught exception while crawling #{url}: #{e.inspect}"
    end
  end
end

module Constants
    ANEMONE_USER_AGENT     = "Googlebot"
    ANEMONE_DELAY          = 5 #seconds
    ANEMONE_MAX_QUEUE_SIZE = 10
    ANEMONE_READ_TIMEOUT   = 60
    ANEMONE_THREADS        = 10
    ANEMONE_SKIP_LINKS     = [
        /(?i)error\.aspx/,
        /404\.aspx/,
        /(?i)\.(axd|rss|atom|json|css|sit|ppt|xls|js)(\?.*)?$/,
        /(?i)\.(gif|jpg|jpeg|bmp|png|tif|tiff|ico|eps|ps|wmf|fpx|cur|ani|img|lwf|pcd|psp|psd|tga|xbm|xpm)(\?.*)?$/,
        /(?i)\.(arj|arc|7z|cab|lzw|lha|lzh|zip|gz|tar.tgz|sit|rpm|deb.pkg)(\?.*)?$/,
        /(?i)\.(mid|midi|rmi|mpeg|mpg|mpe|mp3|mp2|aac|mov|fla|flv|ra|ram|rm|rmv|wma|wmv|wav|wave|ogg|avi|au|snd|dvf|msv)(\?.*)?$/,
        /(?i)\.(exe|com)(\?.*)?$/,
        /(?i)\.(lnk|t3x|iso|bin|.mso|thmx|kml|xps)(\?.*)?$/,
        /(?i)^(file|ftp|mailto):/,
        /[*!@;]/,
        /(?i)calendar|displaycalendar|event|community-calendar|\?month=|date|add-event|calevents|year|towncalendar|phpicalendar|scheduler|calendar-of-events|option=com_jcalpro|eventCal|phpEventCalendar/,
        /(?i)Design=PrintView/,
        /doc_details/,
        /doc_view/,
        /LanapCaptcha.aspx/, # Gov Office
        /wp-includes/,       # Wordpress Related
        /wp-admin/,          # Wordpress Related
        /includes/,          # Wordpress Related
        /modules/,           # Drupal
        /sites/,             # Drupal
        /themes/,            # Drupal
        /(?i)admin/,
        /(?i)search/,
        /(?i)images/,
        /(?i)cache/,
        /(?i)language/,
        /(?i)plugins/,
        /(?i)temp/,
        /(?i)tmp/,
        /(?i)error/,
        /(?i)login/,
        /(?i)gallery/,
        /(?i)contact/,
        /(?i)rss/,
        /(?i)type=atom/,
        /(?i)xmlrpc/,
        /(?i)recoverpassword/,
        /\/.*(\/[^\/]+)\/[^\/]+\1\/[^\/]+\1\//, # URLs with slash-delimited segment that repeats 3+ times, to break loops
    ]
  end