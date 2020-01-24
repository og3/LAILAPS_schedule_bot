namespace :get_news do
  task get_news: :environment do
    require 'selenium-webdriver'
    News.starting_headless_chrome
    News.get_to_new_post
    News.get_title_and_url
    News.quit_driver
  end
end
