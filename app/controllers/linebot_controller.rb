class LinebotController < ApplicationController
    require 'line/bot'  # gem 'line-bot-api'
    require 'date'
    require 'holiday_jp'
  
    # callbackアクションのCSRFトークン認証を無効
    protect_from_forgery :except => [:callback]
  
    # モデルに切り出し予定
    WEEK = { 1 => "月曜日", 2 => "火曜日", 3 => "水曜日", 4 => "木曜日", 5 => "金曜日", 6 => "土曜日", 7 => "日曜日" }.freeze

    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end
  
    def get_lesson_of_now_and_next
        lesson_of_now = Lesson.find_by(day_of_the_week: Time.current.wday, start_on_int: [-Float::INFINITY..Time.current.strftime('%H%M').to_i], end_on_int: [Time.current.strftime('%H%M').to_i..Float::INFINITY])
        lesson_of_next = Lesson.find_by(day_of_the_week: Time.current.wday, number_of_lessons: lesson_of_now.number_of_lessons + 1)
        if lesson_of_next.nil?
          @message = "本日のレッスンは終了しました"
          return @message
        elsif lesson_of_now.name == "閉館"
          @message = "現在は、閉館中です。\n時間：#{lesson_of_now.start_on.strftime('%H：%M')}〜#{lesson_of_now.end_on.strftime('%H：%M')}\n\n次回のレッスンは、#{lesson_of_next.name}です\nトレーナー：#{lesson_of_next.trainer}\n時間：#{lesson_of_next.start_on.strftime('%H：%M')}〜#{lesson_of_next.end_on.strftime('%H：%M')}"
        else
          @message = "現在のレッスンは、#{lesson_of_now.name}です\nトレーナー：#{lesson_of_now.trainer}\n時間：#{lesson_of_now.start_on.strftime('%H：%M')}〜#{lesson_of_now.end_on.strftime('%H：%M')}\n\n次回のレッスンは、#{lesson_of_next.name}です\nトレーナー：#{lesson_of_next.trainer}\n時間：#{lesson_of_next.start_on.strftime('%H：%M')}〜#{lesson_of_next.end_on.strftime('%H：%M')}"
        end
        # 切り出し？
        if HolidayJp.holiday?(Date.today)
          @message << "\n本日は祝日なので、休館の可能性があります！\n公式情報を参照してください！"
        end
        @message
    end

    def get_todays_lesson
        lessons_of_today = Lesson.where(day_of_the_week: Time.current.wday)
        @message = "本日のレッスンは以下の通りです\n\n"
        lessons_of_today.each do |lesson|
            @message << "#{lesson.start_on.strftime('%H：%M')}~  #{lesson.name}：#{lesson.trainer}\n"
        end
        @message
    end

    def get_all_lessons
        lessons = Lesson.all
        @message = "１週間のスケジュールは以下の通りです\n\n"
        count = 0
        lessons.each do |lesson|
            if count != lesson.day_of_the_week
                @message << "#{WEEK[lesson.day_of_the_week]}\n"
                count = lesson.day_of_the_week
            end
            @message << "#{lesson.start_on.strftime('%H：%M')}~  #{lesson.name}：#{lesson.trainer}\n"
        end
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
          response = get_lesson_of_now_and_next
        elsif event.message['text'] == "今日"
          response = get_todays_lesson
        elsif event.message['text'] == "全て"
            response = get_all_lessons
        elsif event.message['text'] == "使い方"
            response = "「今」と入力すると、現在行われているレッスンと、その次に行われるレッスンが表示されます\n\n「今日」と入力すると、今日行われる全てのレッスンが表示されます\n\n「全て」と入力すると１週間全てのレッスンが表示されます"
        else
          response = "使えるワードは「今」、「今日」、「全て」のみです（機能は随時追加予定です）"
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
