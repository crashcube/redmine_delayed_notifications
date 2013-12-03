module Zeed
  module MailerPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        unloadable

        alias_method_chain :issue_edit, :send_mail_control
        alias_method_chain :issue_add, :send_mail_control
        alias_method_chain :wiki_content_updated, :send_mail_control
      end
    end
  end

  module InstanceMethods

    def issue_edit(journal, to_users, cc_users, instant = false)

      to_users = issue.notified_users unless to_users
      cc_users = issue.notified_watchers - to unless cc_users

      if journal.kind_of?(Array)
        journals = journal

        journal = journal.last

        journals.each do |j|
          journal.details.concat(j.details)
        end
      end

      issue = journal.journalized
      redmine_headers 'Project' => issue.project.identifier,
                      'Issue-Id' => issue.id,
                      'Issue-Author' => issue.author.login
      redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
      message_id journal
      references issue
      @author = journal.user
      s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
      s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
      s << issue.subject
      @issue = issue
      @users = to_users + cc_users
      @journal = journal
      @journal_details = journal.visible_details(@users.first)
      @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")

      unless instant
        Notification.create(
            :action => 'issue_edit',
            :entity_id => issue.id,
            :param_id => journal.id,
            :param_model => journal.class.name
        )

        to_users = []
        cc_users = []
      end

      mail :to => to_users.map(&:mail),
           :cc => cc_users.map(&:mail),
           :subject => s
    end

    def wiki_content_updated(wiki_content, instant = false)

      if wiki_content.kind_of?(Array)
        wiki_contents = wiki_content
        wiki_content = wiki_content.last
      else
        wiki_contents = nil
      end

      redmine_headers 'Project' => wiki_content.project.identifier,
                      'Wiki-Page-Id' => wiki_content.page.id
      @author = wiki_content.author
      message_id wiki_content
      recipients = wiki_content.recipients
      cc = wiki_content.page.wiki.watcher_recipients + wiki_content.page.watcher_recipients - recipients
      @wiki_content = wiki_content
      @wiki_content_url = url_for(:controller => 'wiki', :action => 'show',
                                  :project_id => wiki_content.project,
                                  :id => wiki_content.page.title)
      @wiki_diff_url = url_for(:controller => 'wiki', :action => 'diff',
                               :project_id => wiki_content.project, :id => wiki_content.page.title,
                               :version => wiki_content.version)

      unless instant
        Notification.create(
            :action => 'wiki_content_updated',
            :entity_id => wiki_content.page.id,
            :param_id => wiki_content.id,
            :param_model => wiki_content.class.name
        )

        recipients = []
        cc = []
      end

      mail :to => recipients,
           :cc => cc,
           :subject => "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_updated, :id => wiki_content.page.pretty_title)}"
    end

  end
end

Mailer.send(:include, Zeed::MailerPatch)