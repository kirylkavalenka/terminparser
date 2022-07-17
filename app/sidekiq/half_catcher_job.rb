class HalfCatcherJob
  include Sidekiq::Job

  def perform
    return unless Rails.cache.fetch(:termin_url).present?
    sleep(27)
    Catcher.new.perform
  end
end
