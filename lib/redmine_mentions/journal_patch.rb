module RedmineMentions
  module JournalPatch
    def self.included(base)
      base.class_eval do
        after_create :send_mail
        
        def send_mail
          if self.journalized.is_a?(Issue) && self.notes.present?
            issue = self.journalized
            project=self.journalized.project
            users=project.users.to_a.delete_if{|u| (u.type != 'User' || u.mail.empty?)}
            users_regex=users.collect{|u| "#{Setting.plugin_redmine_mentions['trigger']}#{u.firstname}\/#{u.id}"}.join('|')
            regex_for_email = '\B('+users_regex+')\b'
            regex = Regexp.new(regex_for_email)
            mentioned_users = self.notes.scan(regex)
            mentioned_users.each do |mentioned_user|
              user_id = mentioned_user.first[/\/\d+$/].delete('/')
              if user = User.find_by_id(user_id)
                MentionMailer.notify_mentioning(issue, self, user).deliver
              end
            end
          end
        end
      end
    end
  end
end
