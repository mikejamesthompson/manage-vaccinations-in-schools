# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  date_of_birth             :date             not null
#  date_of_death             :date
#  date_of_death_recorded_at :datetime
#  family_name               :string           not null
#  gender_code               :integer          default("not_known"), not null
#  given_name                :string           not null
#  home_educated             :boolean
#  invalidated_at            :datetime
#  nhs_number                :string
#  pending_changes           :jsonb            not null
#  preferred_family_name     :string
#  preferred_given_name      :string
#  registration              :string
#  restricted_at             :datetime
#  updated_from_pds_at       :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  cohort_id                 :bigint
#  school_id                 :bigint
#
# Indexes
#
#  index_patients_on_cohort_id            (cohort_id)
#  index_patients_on_family_name_trigram  (family_name) USING gin
#  index_patients_on_given_name_trigram   (given_name) USING gin
#  index_patients_on_names_family_first   (family_name,given_name)
#  index_patients_on_names_given_first    (given_name,family_name)
#  index_patients_on_nhs_number           (nhs_number) UNIQUE
#  index_patients_on_school_id            (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (school_id => locations.id)
#

require_relative "../../lib/faker/address"

FactoryBot.define do
  sequence :nhs_number_counter, 1

  factory :patient do
    transient do
      parents { [create(:parent, family_name:)] }
      performed_by { association(:user) }
      programme { session&.programmes&.first }
      session { nil }
      organisation do
        session&.organisation ||
          association(:organisation, programmes: [programme].compact)
      end
      year_group { nil }
      location_name { nil }
    end

    cohort do
      Cohort.find_or_create_by!(
        birth_academic_year: date_of_birth.academic_year,
        organisation:
      )
    end

    nhs_number do
      # Prevents duplicate NHS numbers by sequencing and appending a check
      # digit. See Faker's implementation for details:
      # https://github.com/faker-ruby/faker/blob/6ba06393f47d4018b5fdbdaaa04eb9891ae5fb55/lib/faker/default/national_health_service.rb
      base = 999_000_000 + generate(:nhs_number_counter)
      sum = base.to_s.chars.map.with_index { |d, i| d.to_i * (10 - i) }.sum
      check_digit = (11 - (sum % 11)) % 11
      redo if check_digit == 10 # Retry if check digit is 10, which is invalid

      "#{base}#{check_digit}"
    end

    given_name { Faker::Name.first_name }
    family_name { Faker::Name.last_name }
    date_of_birth do
      if year_group
        Faker::Date.birthday(min_age: year_group + 5, max_age: year_group + 5)
      else
        Faker::Date.birthday(min_age: 7, max_age: 16)
      end
    end
    school { session.location if session&.location&.school? }
    registration do
      "#{date_of_birth.year_group}#{Faker::Alphanumeric.alpha(number: 2)}"
    end

    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    address_town { Faker::Address.city }
    address_postcode { Faker::Address.uk_postcode }

    after(:create) do |patient, evaluator|
      if evaluator.session &&
           !PatientSession.exists?(patient:, session: evaluator.session)
        create(:patient_session, patient:, session: evaluator.session)
      end

      evaluator.parents.each do |parent|
        create(:parent_relationship, parent:, patient:)
      end
    end

    trait :home_educated do
      school { nil }
      home_educated { true }
    end

    trait :deceased do
      date_of_death { Date.current }
      date_of_death_recorded_at { Time.current }
    end

    trait :invalidated do
      invalidated_at { Time.current }
    end

    trait :restricted do
      restricted_at { Time.current }
    end

    trait :consent_request_sent do
      after(:create) do |patient, context|
        create(
          :consent_notification,
          :request,
          patient:,
          programme: context.programme,
          sent_at: 1.week.ago
        )
      end
    end

    trait :initial_consent_reminder_sent do
      after(:create) do |patient, context|
        create(
          :consent_notification,
          :initial_reminder,
          patient:,
          programme: context.programme
        )
      end
    end

    trait :consent_given_triage_not_needed do
      consents do
        [
          association(
            :consent,
            :recorded,
            :given,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :consent_given_triage_needed do
      consents do
        [
          association(
            :consent,
            :recorded,
            :given,
            :from_mum,
            :health_question_notes,
            patient: instance,
            programme:,
            organisation:
          )
        ]
      end
    end

    trait :consent_refused do
      consents do
        [
          association(
            :consent,
            :recorded,
            :refused,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :consent_refused_with_notes do
      consents do
        [
          association(
            :consent,
            :recorded,
            :refused,
            :from_mum,
            patient: instance,
            organisation:,
            programme:,
            reason_for_refusal: "already_vaccinated",
            notes: "Already had the vaccine at the GP"
          )
        ]
      end
    end

    trait :consent_conflicting do
      consents do
        [
          association(
            :consent,
            :recorded,
            :refused,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          ),
          association(
            :consent,
            :recorded,
            :given,
            :from_dad,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :consent_not_provided do
      consents do
        [
          association(
            :consent,
            :recorded,
            :not_provided,
            :from_mum,
            patient: instance,
            organisation:,
            programme:
          )
        ]
      end
    end

    trait :triage_ready_to_vaccinate do
      triages do
        [
          association(
            :triage,
            :ready_to_vaccinate,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Okay to vaccinate"
          )
        ]
      end
    end

    trait :triage_do_not_vaccinate do
      triages do
        [
          association(
            :triage,
            :do_not_vaccinate,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Do not vaccinate"
          )
        ]
      end
    end

    trait :triage_needs_follow_up do
      triages do
        [
          association(
            :triage,
            :needs_follow_up,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Needs follow up"
          )
        ]
      end
    end

    trait :triage_delay_vaccination do
      triages do
        [
          association(
            :triage,
            :delay_vaccination,
            patient: instance,
            performed_by:,
            programme:,
            organisation:,
            notes: "Delay vaccination"
          )
        ]
      end
    end

    trait :vaccinated do
      vaccination_records do
        [
          if session
            association(
              :vaccination_record,
              patient: instance,
              programme:,
              session:,
              location_name:
            )
          else
            association(:vaccination_record, patient: instance, programme:)
          end
        ]
      end
    end
  end
end
