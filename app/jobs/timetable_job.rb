require 'google/cloud/firestore'
require 'open-uri'
require "chromedriver-helper"
require "selenium-webdriver"
class TimetableJob < ApplicationJob
  class_timeout 120

  cron "0 15 * * ? *" # every 12 am (KST)
  def fetch
    firestore = Google::Cloud::Firestore.new
    school_info_doc = firestore.doc "timetable/school_info"
    snapshot = school_info_doc.get
    response = ""
    # 컴시간 JSON Response내에서도 업데이트 시간을 가져올 수 있지만 키가 바뀔 가능성이 있기 때문에 
    # Headless Chrome을 이용하여 정상 웹 브라우저로 위장한 후 업데이트 일자를 불러옴
    Selenium::WebDriver::Chrome::Service.driver_path = "/opt/bin/chrome/chromedriver"
    options = Selenium::WebDriver::Chrome::Options.new(binary: "/opt/bin/chrome/headless-chromium")
    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    options.add_argument("--headless")
    options.add_argument('--no-sandbox')
    options.add_argument('--single-process')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument("--window-size=1920x1080")
    options.add_argument("lang=ko-KR")
    options.add_argument("plugins-length=5")
    options.add_argument("user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36")
    driver = Selenium::WebDriver.for(:chrome, options: options)
    driver.get("http://comci.kr:4081/st")
    driver.find_element(name: 'sc2').send_keys('과천고등학교')
    driver.find_element(css: 'input[value="검색"]').click()
    school = wait.until{driver.find_element(css: 'a[onclick$="(97976)"]')}
    school.click()
    selected = wait.until{driver.find_element(css: "option[value='3-8']")}
    selected.click()
    # 학교 로드 완료

    last_updated = fetch_last_updated(driver, wait)
    if snapshot.data[:last_updated] < last_updated
      time_then = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      puts "[TimetableJob] Timetable data is outdated, updating..."
      # 교실 정보 업데이트
      classes = fetch_class_list(driver, wait)
      classes_count = 0
      classes.each do |c|
        classes_count += c
      end
      school_info_data = {
        classes: classes,
        last_updated: last_updated
      }
      school_info_doc.set(school_info_data)

      # 시간표 업데이트
      for sg in classes.length.downto(1)
        for sc in classes[sg- 1].downto(1)
          fetch_and_update_timetable(driver, wait, firestore, sg, sc)
          next_elem = wait.until{driver.find_element(css: "input[value=◀]")}
          next_elem.click()
        end
      end
      driver.quit
      time_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = time_now - time_then
      puts "[TimetableJob] Operation for the date #{last_updated} completed in #{elapsed.round(2)} seconds"
      response = {status: true, message: "Operation for the date #{last_updated} completed in #{elapsed.round(2)} seconds"}
    else
      driver.quit
      puts "[TimetableJob] Timetable data is already up to date"
      response = {status: false, message: "Timetable data is already up to date"}
    end

    return response
  end

  def fetch_and_update_timetable(driver, wait, firestore, schoolGrade, schoolClass)
    identifier = "#{schoolGrade}-#{schoolClass}"
    document = Nokogiri::HTML(driver.page_source)
    data_rows = document.css('#hour > table > tbody > tr')

    data = data_rows.map { |data_row|
      data_row.css('td').map(&:text)
    }
    data.shift
    data[0][0] = identifier
    date = []
    data[0].each do |d|
      date << d.gsub(/\([^\)]*\)*/, '')
    end
    data[0] = date
    data.pop
    data.each_with_index do |d, i|
      if i != 0
        divided = d[0].split('(')
        data[i][0] = divided[0] << "교시|(#{divided[1]}"
        for j in 1..5
          divided = d[j].scan(/.{1,2}/).join('|')
          data[i][j] = divided
        end
      else
        for j in 0..6
          data[0][j] = data[0][j] + "|"
        end
      end
      data[i].pop
    end
    timetable_doc = firestore.doc "timetable/#{identifier}"
    timetable_data = {}
    data.each_with_index do |d, i|
      timetable_data.store(i, d)
    end
    timetable_doc.set(timetable_data)
    puts "[TimetableJob] Successfully fetched timetable with ID #{schoolGrade}-#{schoolClass}"
  end

  def fetch_class_list(driver, wait)
    found = wait.until{
      element = driver.find_element(css: '#ba')
      options = element.find_elements(tag_name: 'option')
      options if options.size != 0 
    }
    class_list = []
    found.each do |o|
      class_list << o.text
    end
    class_list.shift

    first_grade = []
    second_grade = []
    third_grade = []
    class_list.each do |c|
      if (c.starts_with?("1-"))
        first_grade << c
      elsif (c.starts_with?("2-"))
        second_grade << c
      elsif (c.starts_with?("3-"))
        third_grade << c
      end
    end
    return [first_grade.size, second_grade.size, third_grade.size]
  end

  def fetch_last_updated(driver, wait)
    found = wait.until{
      element = driver.find_element(css: '#수정일')
      element if element.displayed?
    }
    # 수동으로 Timezone 지정
    last_updated = DateTime.parse(found.text.partition(': ').pop()).asctime.in_time_zone("Asia/Seoul")

    return last_updated
  end
end
