class CatcherJob
  include Sidekiq::Job

  def perform
    Catcher.new(notify: true).perform
  end
end
