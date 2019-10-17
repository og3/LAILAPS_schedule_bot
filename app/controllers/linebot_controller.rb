class LinebotController < ApplicationController
    require 'line/bot'  # gem 'line-bot-api'

    # callbackアクションのCSRFトークン認証を無効
    protect_from_forgery :except => [:callback]
  
    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end
  
    def answer_for_word_of_now
        lesson_of_now = Lesson.find_by(day_of_the_week: Time.current.wday, start_on: [-Float::INFINITY..Time.current.strftime('%H%M').to_i])
        lesson_of_next = Lesson.find_by(day_of_the_week: Time.current.wday, number_of_lessons: lesson_of_now.number_of_lessons + 1)
        @message = "現在のレッスンは、#{lesson_of_now.name}です。\nトレーナー：#{lesson_of_now.trainer}\n時間：#{lesson_of_now.start_on.strftime('%H：%M')}〜#{lesson_of_now.end_on.strftime('%H：%M')}まで\n\n次回のレッスンは#{lesson_of_next.name}です\nトレーナー：#{lesson_of_next.trainer}\n時間：#{lesson_of_next.start_on.strftime('%H：%M')}〜#{lesson_of_next.end_on.strftime('%H：%M')}まで"
        @message
    end

    def callback
  
      body = request.body.read
  
      signature = request.env['HTTP_X_LINE_SIGNATURE']
      unless client.validate_signature(body, signature)
        head :bad_request
      end
  
      events = client.parse_events_from(body)
  
      events.each { |event|
  
        # event.message['text']でLINEで送られてきた文書を取得
        if event.message['text'] == "今"
          response = answer_for_word_of_now
        else
          response = "使えるワードは「今」、「今日」、「全て」、「休館日」のみです"
        end
        #if文でresponseに送るメッセージを格納
  
        case event
        when Line::Bot::Event::Message
          case event.type
          when Line::Bot::Event::MessageType::Text
            message = {
              type: 'text',
              text: response
            }
            client.reply_message(event['replyToken'], message)
          end
        end
      }
  
      head :ok
    end
end
