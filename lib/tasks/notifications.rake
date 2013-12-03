namespace :notifications do
  desc 'Send delayed notifications'
  task :send => :environment do
    Notification.group('entity_id, action').each do |n|

      notifications = Notification.where(:entity_id => n.entity_id, :action => n.action)

      if notifications.length < 2 && (Time.now - n.created_at) > 300

        param = n.param_model.constantize.find(n.param_id)
        message = Mailer.send(n.action.to_sym, param, true)
        message.deliver
        n.destroy

      elsif (Time.now - notifications.last.created_at) > 300

        params = []

        notifications.each do |x|
          params << x.param_model.constantize.find(x.param_id)
          x.destroy
        end

        message = Mailer.send(n.action.to_sym, params, true)
        message.deliver

      end

    end
  end
end