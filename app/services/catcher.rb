require 'telegram/bot'
require 'selenium-webdriver'

class Catcher
  START_URL = 'https://otv.verwalt-berlin.de/ams/TerminBuchen'.freeze
  BOOK_TERMIN = 'Termin buchen'.freeze
  NEXT_BUTTON = 'applicationForm:managedForm:proceed'.freeze
  TG_BOT='5465276324:AAEmw_hjLCh6FIPhQIrSTUeSFSDVcmh_1rs'.freeze

  def initialize(notify: false)
    @notify = notify
    @browser = Selenium::WebDriver.for :chrome
  end

  def perform
    if [0].include?(Time.now.min)
      Telegram::Bot::Client.run(TG_BOT) do |b|
        b.api.send_message(chat_id: 147775599, text: 'Im working')
      end if notify
    end

    if Rails.cache.fetch(:termin_url).present?
      main_flow
    else
      initial_flow
    end
  ensure
    browser.quit
  end

  private

  attr_reader :browser, :notify

  def main_flow
    browser.get(Rails.cache.fetch(:termin_url))
    sleep(rand(7..9))

    click_next_button

    sleep(17)
    check_response
  end

  def initial_flow
    browser.get(START_URL)
    sleep(2)
    click_termin_buchen_button
    sleep(12)
    check_agreement_box
    click_next_button
    sleep(12)
    check_from_dropdown('xi-sel-400', "Belarus")
    sleep(2)
    check_from_dropdown('xi-sel-422', "zwei Personen")
    sleep(2)
    check_from_dropdown('xi-sel-427', "ja")
    sleep(2)
    check_from_dropdown('xi-sel-428', "Russische Föderation")
    sleep(10)
    click_get_permit_button
    sleep(10)
    click_accordeon
    sleep(10)
    check_blue_karte
    sleep(10)
    click_next_button
    sleep(10)
    check_response
  end

  def click_termin_buchen_button
    buttons = browser.find_elements(:class=> 'button')
    buttons.select{|el| el.text == BOOK_TERMIN}.first.click
  end

  def check_agreement_box
    browser.find_element(:id, 'xi-cb-1').click
  end

  def click_next_button
    browser.find_element(:id, NEXT_BUTTON).click
  end

  def check_from_dropdown(dropdown_id, value)
    drop = browser.find_element(:id, dropdown_id)
    choose = Selenium::WebDriver::Support::Select.new(drop)
    choose.select_by(:text, value)
  end

  def click_get_permit_button
    buttons = browser.find_elements(:class, 'ozg-kachel')
    buttons.select{|el| el.text == 'Aufenthaltstitel - beantragen'}.first.click
  end

  def click_accordeon
    buttons = browser.find_elements(:class, 'ozg-accordion')
    buttons.select{|el| el.text == 'Erwerbstätigkeit'}.first.click
  end

  def check_blue_karte
    browser.find_element(:id, 'SERVICEWAHL_DE169-0-1-1-324659').click
  end

  def check_response
    Rails.cache.write(:termin_url, browser.current_url)

    current_page = browser.find_element(:class, 'antcl_active')&.text

    if current_page.include?('Terminauswahl')
      proceed_time_slots
    else
      puts "No slots"
    end
  end

    #error = browser.find_element(:class, 'errorMessage')&.text
  def proceed_time_slots
    sleep(4)
    browser.save_screenshot("#{Time.now.to_i}.png")
    Telegram::Bot::Client.run(TG_BOT) { |b| b.api.send_message(chat_id: 147775599, text: browser.current_url) }
    Telegram::Bot::Client.run(TG_BOT) { |b| b.api.send_message(chat_id: 762828011, text: browser.current_url) }

    click_next_button
    sleep(600)
  end
end
