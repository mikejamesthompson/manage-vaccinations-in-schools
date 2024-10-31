# frozen_string_literal: true

require_relative "../task_helpers"

namespace :organisations do
  desc <<-DESC
    Create a new HPV organisation consisting of a organisation, programme, vaccine, and health questions.
  
    Usage:
      rake organisations:create_hpv # Complete the prompts
      rake organisations:create_hpv[email,name,phone,ods_code,privacy_policy_url,reply_to_id]
  DESC
  task :create_hpv,
       %i[email name phone ods_code privacy_policy_url reply_to_id] =>
         :environment do |_task, args|
    include TaskHelpers

    unless Vaccine.exists?
      raise "Ensure vaccines exist before creating a organisation."
    end

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      email = prompt_user_for "Enter organisation email:", required: true
      name = prompt_user_for "Enter organisation name:", required: true
      phone = prompt_user_for "Enter organisation phone:", required: true
      ods_code = prompt_user_for "Enter ODS code:", required: true
      privacy_policy_url = prompt_user_for "Enter privacy policy URL:"
      reply_to_id = prompt_user_for "Reply-to ID (from GOVUK Notify):"
    elsif args.to_a.size == 6
      email = args[:email]
      name = args[:name]
      phone = args[:phone]
      ods_code = args[:ods_code]
      privacy_policy_url = args[:privacy_policy_url]
      reply_to_id = args[:reply_to_id]
    elsif args.to_a.size != 6
      raise "Expected 6 arguments got #{args.to_a.size}"
    end

    ActiveRecord::Base.transaction do
      programme = Programme.find_or_create_by!(type: "hpv")

      organisation =
        Organisation.create!(
          email:,
          name:,
          phone:,
          ods_code:,
          privacy_policy_url:,
          reply_to_id:
        )

      OrganisationProgramme.create!(organisation:, programme:)

      organisation.generic_clinic # ensure it exists, this also creates a generic team

      puts "New #{organisation.name} organisation with ID #{organisation.id} created."
    end
  end
end