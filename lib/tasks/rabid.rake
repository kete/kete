namespace :rabid do
  desc 'Merges users who have multiple accounts on same email address.'
  task fixup_duplicate_users: :environment do
    all_emails = User.select(:email).all.map(&:email)
    log("There are #{all_emails.count} accounts in the system")

    duplicate_emails = all_emails.select { |email| all_emails.count(email) > 1 }.uniq
    log("There are #{duplicate_emails.count} duplicate accounts in the system")

    duplicate_emails.each do |email|
      accounts = User.where(email: email).all
      primary_acc, *alias_accs = *accounts # primary account is assumed to be the first account

      log("User #{primary_acc.id} is chosen as primary account")
      log "Users #{alias_accs.map(&:id)} are alias accounts"

      alias_accs.each do |alias_acc|
        log('Contribution')
        change_has_one(Contribution.where(user_id: alias_acc.id), alias_acc, primary_acc)
        log('Import')
        change_has_one(Import.where(user_id: alias_acc.id), alias_acc, primary_acc)
        log('Search')
        change_has_one(Search.where(user_id: alias_acc.id), alias_acc, primary_acc)
        log('UserPortraitRelation')
        change_has_one(UserPortraitRelation.where(user_id: alias_acc.id), alias_acc, primary_acc)

        change_has_many(alias_acc.roles, alias_acc, primary_acc)

        # Now that all references to this user in the system have been removed
        # we can delete the user.
        alias_acc.destroy
      end
    end
  end

  def change_has_one(instances, from_user, to_user)
    log("User #{from_user.id} is referenced from the following models: #{instances.map(&:id)}")

    instances.each do |instance|
      log("Editing #{instance.id} to reference User #{to_user.id} (from User #{from_user.id})")
      instance.user = to_user
      log('Saving')
      instance.save
    end
  end

  def change_has_many(instances, from_user, to_user)
    log("User #{from_user.id} is referenced from the following model ids: #{instances.map(&:id)}")

    instances.each do |instance|
      log("Editing #{instance.id} to replace User #{from_user.id}) with User #{to_user.id} ")
      log("Old user ids: #{instance.user_ids}")
      ids = instance.user_ids - [from_user.id] + [to_user.id]
      instance.user_ids = ids.uniq
      log("New user ids: #{instance.user_ids}")
      log('Saving')
      instance.save
    end
  end

  def log(message)
    puts message
  end
end
