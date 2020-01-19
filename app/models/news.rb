class News < ApplicationRecord
  require 'selenium-webdriver'
  require 'webdrivers'

  @@driver

  # headlessモードで起動
  def self.starting_headless_chrome
    Selenium::WebDriver::Chrome.path = ENV.fetch('GOOGLE_CHROME_BIN', nil)

    options = Selenium::WebDriver::Chrome::Options.new(
      prefs: { 'profile.default_content_setting_values.notifications': 2 },
      binary: ENV.fetch('GOOGLE_CHROME_SHIM', nil)
    )
    options.add_argument('--headless')
    @@driver = Selenium::WebDriver.for :chrome, options: options
  end

  # 公式ページへ移動
  def self.get_to_new_post
    @@driver.get('https://lailaps-hokusei.jp/')
    sleep 2
    @@driver.find_element(:xpath, '/html/body/div[6]/div/div[5]/div[1]/ul/li[1]/a').click
    sleep 2
  end

  # 最新記事を取得する
  def self.get_title_and_url
    # 最新記事のURLを取得
    url = @@driver.current_url
    # 最新記事のタイトルを取得
    title = @@driver.find_element(:xpath, '/html/body/div[4]/div/div[1]/div[1]/div/h1').text
    News.save_new_post(title, url)
  end

  def self.save_new_post(title, url)
    # idが１のレコードがなかったら作る
    if !News.where(id: 1).exists?
      News.create(id: 1, title: nil, url: nil)
    end
    @news = News.find(1)
    if @news != url
      @news.update(title: title, url: url)
    end
    sleep 2
  end

  # ブラウザを終了させる
  def self.quit_driver
    @@driver.quit
  end

  def self.send_new_post
    news = News.find(1)
    @message = "最新記事は、以下の通りです。\n\n#{news.title}\n#{news.url}\n更新日#{news.updated_at.in_time_zone('Tokyo')}"
  end
end
