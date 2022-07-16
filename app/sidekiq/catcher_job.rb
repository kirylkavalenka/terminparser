class CatcherJob
  include Sidekiq::Job

  def perform
    Catcher.new.perform
  end
end
