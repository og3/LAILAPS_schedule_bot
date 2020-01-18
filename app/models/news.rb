class News < ApplicationRecord
  require 'selenium-webdriver'
  @@driver

  # headlessモードで起動
  def self.starting_headless_chrome
    options = Selenium::WebDriver::Chrome::Options.new
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
end
