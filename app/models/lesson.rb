class Lesson < ApplicationRecord
  require 'date'
  require 'holiday_jp'

  WEEK = { 1 => "月曜日", 2 => "火曜日", 3 => "水曜日", 4 => "木曜日", 5 => "金曜日", 6 => "土曜日", 0 => "日曜日" }.freeze

  def get_lesson_of_now_and_next
    lesson_of_now = Lesson.find_by(day_of_the_week: Time.current.wday, start_on_int: [-Float::INFINITY..Time.current.strftime('%H%M').to_i], end_on_int: [Time.current.strftime('%H%M').to_i..Float::INFINITY])
    lesson_of_next = Lesson.find_by(day_of_the_week: Time.current.wday, number_of_lessons: lesson_of_now.number_of_lessons + 1)
    if lesson_of_next.nil?
      @message = "本日のレッスンは終了しました"
      return @message
    elsif lesson_of_now.name == "閉館"
      @message = "現在は、閉館中です。\n\n次回のレッスンは、#{lesson_of_next.name}です\nトレーナー：#{lesson_of_next.trainer}\n時間：#{lesson_of_next.start_on.strftime('%H：%M')}〜#{lesson_of_next.end_on.strftime('%H：%M')}\n"
    else
      @message = "現在のレッスンは、#{lesson_of_now.name}です\nトレーナー：#{lesson_of_now.trainer}\n時間：#{lesson_of_now.start_on.strftime('%H：%M')}〜#{lesson_of_now.end_on.strftime('%H：%M')}\n\n次回のレッスンは、#{lesson_of_next.name}です\nトレーナー：#{lesson_of_next.trainer}\n時間：#{lesson_of_next.start_on.strftime('%H：%M')}〜#{lesson_of_next.end_on.strftime('%H：%M')}\n"
    end
    @message + check_holiday
  end

  def get_todays_lesson
    lessons_of_today = Lesson.where(day_of_the_week: Time.current.wday)
    @message = "本日のレッスンは以下の通りです\n\n#{WEEK[Time.current.wday]}\n"
    lessons_of_today.each do |lesson|
        @message << "#{lesson.start_on.strftime('%H：%M')}~  #{lesson.name}：#{lesson.trainer}\n"
    end
    @message + check_holiday
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

  private

  def check_holiday
    if HolidayJp.holiday?(Date.today)
      @holiday_message = "\n本日は祝日なので、休館の可能性があります。公式情報を参照してください。"
    else
      # 文字列結合をさせているのでnilだとエラーが出る。なんとかしたいポイント。
      @holiday_message = ""
    end
  end

end
