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

  def callback

    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)
    # メソッド呼び出し用のインスタンス
    lesson = Lesson.new

    events.each { |event|

      # event.message['text']でLINEで送られてきた文書を取得
      if event.message['text'] == "今"
        response = lesson.get_lesson_of_now_and_next
      elsif event.message['text'] == "今日"
        response = lesson.get_todays_lesson
      elsif event.message['text'] == "全て"
        response = lesson.get_all_lessons
      elsif event.message['text'] == "使い方"
        response = "「今」と入力すると、現在行われているレッスンと、その次に行われるレッスンが表示されます\n\n「今日」と入力すると、今日行われる全てのレッスンが表示されます\n\n「全て」と入力すると１週間全てのレッスンが表示されます"
      else
        response = "その文字には対応していません！\n使い方は以下の通りです\n\n「今」と入力すると、現在行われているレッスンと、その次に行われるレッスンが表示されます\n\n「今日」と入力すると、今日行われる全てのレッスンが表示されます\n\n「全て」と入力すると１週間全てのレッスンが表示されます"
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
