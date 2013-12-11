module Zeed
  module MailerPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        unloadable

        alias_method_chain :issue_edit, :delay
        alias_method_chain :wiki_content_updated, :delay
      end
    end
  end

  module InstanceMethods

    def issue_edit_with_delay(journal, to_users = nil, cc_users = nil)

      if journal.kind_of?(Array)
        journals = journal

        journal = journal.last

        journals.each do |j|
          journal.details.concat(j.details)
        end
      end

      if to_users.kind_of?(Array)
        Notification.create(
            :action => 'issue_edit',
            :entity_id => issue.id,
            :param_id => journal.id,
            :param_model => journal.class.name
        )

        to_users = []
        cc_users = []
      else
        issue = journal.journalized
        to_users = issue.notified_users
        cc_users = issue.notified_watchers - to_users
      end

      issue_edit_without_delay(journal, to_users, cc_users)

    end

    def wiki_content_updated_with_delay(wiki_content, instant = false)

      if wiki_content.kind_of?(Array)
        wiki_content = wiki_content.last
      end

      unless instant
        Notification.create(
            :action => 'wiki_content_updated',
            :entity_id => wiki_content.page.id,
            :param_id => wiki_content.id,
            :param_model => wiki_content.class.name
        )

        wiki_content.recipients = []
        wiki_content.page.wiki.watcher_recipients = []
        wiki_content.page.watcher_recipients = []
      end

      wiki_content_updated_without_delay(wiki_content)

    end

  end
end

Mailer.send(:include, Zeed::MailerPatch)