# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  closed_at                     :datetime
#  days_before_consent_reminders :integer
#  send_consent_requests_at      :date
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  organisation_id               :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_location_id_academic_year_3496b72d0c  (organisation_id,location_id,academic_year) UNIQUE
#  index_sessions_on_organisation_id                            (organisation_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#

describe Session do
  describe "scopes" do
    let(:programme) { create(:programme) }

    let(:closed_session) { create(:session, :closed, programme:) }
    let(:completed_session) { create(:session, :completed, programme:) }
    let(:scheduled_session) { create(:session, :scheduled, programme:) }
    let(:today_session) { create(:session, :today, programme:) }
    let(:unscheduled_session) { create(:session, :unscheduled, programme:) }

    describe "#today" do
      subject(:scope) { described_class.today }

      it { should contain_exactly(today_session) }
    end

    describe "#upcoming" do
      subject(:scope) { described_class.upcoming }

      it do
        expect(scope).to contain_exactly(
          unscheduled_session,
          today_session,
          scheduled_session
        )
      end
    end

    describe "#unscheduled" do
      subject(:scope) { described_class.unscheduled }

      it { should contain_exactly(unscheduled_session) }

      context "for a different academic year" do
        let(:unscheduled_session) do
          create(:session, :unscheduled, programme:, academic_year: 2023)
        end

        it { should_not include(unscheduled_session) }
      end
    end

    describe "#scheduled" do
      subject(:scope) { described_class.scheduled }

      it { should contain_exactly(today_session, scheduled_session) }
    end

    describe "#completed" do
      subject(:scope) { described_class.completed }

      it { should contain_exactly(completed_session) }

      context "for a different academic year" do
        let(:completed_session) do
          create(:session, :completed, programme:, date: Date.new(2023, 9, 1))
        end

        it { should_not include(completed_session) }
      end
    end

    describe "#closed" do
      subject(:scope) { described_class.closed }

      it { should contain_exactly(closed_session) }
    end
  end

  describe "#open?" do
    subject(:open?) { session.open? }

    let(:session) { build(:session) }

    it { should be(true) }

    context "with a closed session" do
      let(:session) { build(:session, :closed) }

      it { should be(false) }
    end
  end

  describe "#closed?" do
    subject(:closed?) { session.closed? }

    let(:session) { build(:session) }

    it { should be(false) }

    context "with a closed session" do
      let(:session) { build(:session, :closed) }

      it { should be(true) }
    end
  end

  describe "#today?" do
    subject(:today?) { session.today? }

    context "when the session is scheduled for today" do
      let(:session) { create(:session, :today) }

      it { should be(true) }
    end

    context "when the session is scheduled in the past" do
      let(:session) { create(:session, :completed) }

      it { should be(false) }
    end

    context "when the session is scheduled in the future" do
      let(:session) { create(:session, :scheduled) }

      it { should be(false) }
    end
  end

  describe "#unscheduled?" do
    subject(:unscheduled?) { session.reload.unscheduled? }

    let(:session) { create(:session, date: nil) }

    it { should be(true) }

    context "with a date" do
      before { create(:session_date, session:) }

      it { should be(false) }
    end
  end

  describe "#year_groups" do
    subject(:year_groups) { session.year_groups }

    let(:flu_programme) { create(:programme, :flu) }
    let(:hpv_programme) { create(:programme, :hpv) }

    let(:session) do
      create(:session, programmes: [flu_programme, hpv_programme])
    end

    it { should contain_exactly(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) }
  end

  describe "#today_or_future_dates" do
    subject(:today_or_future_dates) do
      travel_to(today) { session.today_or_future_dates }
    end

    let(:dates) do
      [Date.new(2024, 1, 1), Date.new(2024, 1, 2), Date.new(2024, 1, 3)]
    end

    let(:session) { create(:session, academic_year: 2023, dates:) }

    context "on the first day" do
      let(:today) { dates.first }

      it { should match_array(dates) }
    end

    context "on the second day" do
      let(:today) { dates.second }

      it { should match_array(dates.drop(1)) }
    end

    context "on the third day" do
      let(:today) { dates.third }

      it { should match_array(dates.drop(2)) }
    end

    context "after the session" do
      let(:today) { dates.third + 1.day }

      it { should be_empty }
    end
  end

  describe "#close_consent_at" do
    subject(:close_consent_at) { session.close_consent_at }

    let(:date) { nil }

    let(:session) { create(:session, date:) }

    it { should be_nil }

    context "with a date" do
      let(:date) { Date.new(2020, 1, 2) }

      it { should eq(Date.new(2020, 1, 1)) }
    end

    context "with two dates" do
      let(:date) { Date.new(2020, 1, 2) }

      before { session.session_dates.create!(value: date + 1.day) }

      it { should eq(Date.new(2020, 1, 2)) }
    end
  end

  describe "#create_patient_sessions!" do
    subject(:create_patient_sessions!) { session.create_patient_sessions! }

    let(:flu_programme) { create(:programme, :flu) }
    let(:hpv_programme) { create(:programme, :hpv) }
    let(:organisation) { create(:organisation, programmes:) }
    let(:session) { create(:session, organisation:, location:, programmes:) }

    let(:school) { create(:location, :primary) }

    let!(:unvaccinated_child) do
      create(:patient, year_group: 6, organisation:, school:)
    end
    let!(:unvaccinated_teen) do
      create(:patient, year_group: 8, organisation:, school:)
    end
    let!(:unvaccinated_home_educated_child) do
      create(:patient, :home_educated, year_group: 6, organisation:)
    end
    let!(:unvaccinated_home_educated_teen) do
      create(:patient, :home_educated, year_group: 8, organisation:)
    end
    let!(:unvaccinated_unknown_school_child) do
      create(:patient, year_group: 6, organisation:, school: nil)
    end
    let!(:unvaccinated_unknown_school_teen) do
      create(:patient, year_group: 8, organisation:, school: nil)
    end

    let!(:flu_vaccinated_child) do
      create(
        :patient,
        :vaccinated,
        year_group: 6,
        organisation:,
        school:,
        programme: flu_programme
      )
    end
    let!(:flu_vaccinated_teen) do
      create(
        :patient,
        :vaccinated,
        year_group: 8,
        organisation:,
        school:,
        programme: flu_programme
      )
    end
    let!(:hpv_vaccinated_teen) do
      create(
        :patient,
        :vaccinated,
        year_group: 8,
        organisation:,
        school:,
        programme: hpv_programme
      )
    end

    let!(:both_vaccinated_teen) do
      create(:patient, year_group: 8, organisation:, school:)
    end

    before do
      create(
        :vaccination_record,
        programme: flu_programme,
        patient: both_vaccinated_teen
      )
      create(
        :vaccination_record,
        programme: hpv_programme,
        patient: both_vaccinated_teen
      )

      create(:patient, :deceased, year_group: 8, organisation:, school:)
    end

    context "with a Flu session" do
      let(:programmes) { [flu_programme] }

      context "in school" do
        let(:location) { school }

        it "adds unvaccinated patients, proposes moving if in other sessions" do
          create_patient_sessions!

          expect(session.patients).to contain_exactly(
            unvaccinated_child,
            unvaccinated_teen
          )

          # BUG: This patient has an upcoming HPV session, we should not be
          # proposing the move to this Flu session.
          expect(
            PatientSession.where(proposed_session: session).map(&:patient)
          ).to contain_exactly(hpv_vaccinated_teen)
        end

        it "is idempotent" do
          expect { 2.times { create_patient_sessions! } }.not_to raise_error
        end
      end

      context "in a generic clinic" do
        let(:location) { create(:location, :generic_clinic, organisation:) }

        it "adds the unvaccinated patients" do
          create_patient_sessions!

          expect(session.patients).to contain_exactly(
            unvaccinated_home_educated_child,
            unvaccinated_home_educated_teen,
            unvaccinated_unknown_school_child,
            unvaccinated_unknown_school_teen
          )
        end

        it "is idempotent" do
          expect { 2.times { create_patient_sessions! } }.not_to raise_error
        end
      end
    end

    context "with an HPV session" do
      let(:programmes) { [hpv_programme] }

      context "in school" do
        let(:location) { school }

        it "adds unvaccinated patients, proposes moving if in other sessions" do
          create_patient_sessions!

          expect(session.patients).to contain_exactly(unvaccinated_teen)

          # BUG: This patient has an upcoming Flu session, we should not be
          # proposing the move to this HPV session.
          expect(
            PatientSession.where(proposed_session: session).map(&:patient)
          ).to contain_exactly(flu_vaccinated_teen)
        end

        it "is idempotent" do
          expect { 2.times { create_patient_sessions! } }.not_to raise_error
        end
      end

      context "in a generic clinic" do
        let(:location) { create(:location, :generic_clinic, organisation:) }

        it "adds the unvaccinated patients" do
          create_patient_sessions!

          expect(session.patients).to contain_exactly(
            unvaccinated_home_educated_teen,
            unvaccinated_unknown_school_teen
          )
        end

        it "is idempotent" do
          expect { 2.times { create_patient_sessions! } }.not_to raise_error
        end
      end
    end

    context "with a Flu and HPV session" do
      let(:programmes) { [flu_programme, hpv_programme] }

      context "in school" do
        let(:location) { school }

        it "adds unvaccinated patients, proposes moving if in other sessions" do
          create_patient_sessions!

          expect(session.patients).to contain_exactly(
            unvaccinated_child,
            unvaccinated_teen
          )

          expect(
            PatientSession.where(proposed_session: session).map(&:patient)
          ).to contain_exactly(
            flu_vaccinated_child,
            hpv_vaccinated_teen,
            flu_vaccinated_teen
          )
        end

        it "is idempotent" do
          expect { 2.times { create_patient_sessions! } }.not_to raise_error
        end
      end

      context "in a generic clinic" do
        let(:location) { create(:location, :generic_clinic, organisation:) }

        it "adds the unvaccinated patients" do
          create_patient_sessions!

          expect(session.patients).to contain_exactly(
            unvaccinated_home_educated_child,
            unvaccinated_home_educated_teen,
            unvaccinated_unknown_school_child,
            unvaccinated_unknown_school_teen
          )
        end

        it "is idempotent" do
          expect { 2.times { create_patient_sessions! } }.not_to raise_error
        end
      end
    end
  end

  describe "#close!" do
    subject(:close!) { session.close! }

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:session) { create(:session, :completed, programme:, organisation:) }

    it "sets the closed at time" do
      freeze_time do
        expect { close! }.to change(session, :closed_at).from(nil).to(
          Time.current
        )
      end
    end

    context "with vaccinated and unvaccinated patients" do
      let!(:vaccinated_patient) do
        create(:patient, :vaccinated, session:, programme:)
      end

      let(:generic_clinic) { create(:location, :generic_clinic, organisation:) }
      let(:generic_clinic_session) do
        create(:session, location: generic_clinic, organisation:, programme:)
      end

      context "with an unvaccinated patient" do
        let!(:unvaccinated_patient) { create(:patient, session:, programme:) }

        it "adds the unvaccinated patient to the generic clinic session" do
          expect(generic_clinic_session.patients).to be_empty

          close!

          expect(generic_clinic_session.patients).to include(
            unvaccinated_patient
          )
          expect(generic_clinic_session.patients).not_to include(
            vaccinated_patient
          )
        end

        context "with self-consent" do
          let(:consent) do
            create(
              :consent,
              :self_consent,
              patient: unvaccinated_patient,
              programme:
            )
          end

          let(:triage) do
            create(
              :triage,
              patient: consent.patient,
              programme: consent.programme,
              organisation: consent.organisation
            )
          end

          it "invalidates the consent" do
            expect { close! }.to change { consent.reload.invalidated? }.from(
              false
            ).to(true)
          end

          it "invalidates the triage" do
            expect { close! }.to change { triage.reload.invalidated? }.from(
              false
            ).to(true)
          end
        end

        context "with parental consent" do
          let(:consent) do
            create(:consent, patient: unvaccinated_patient, programme:)
          end

          let(:triage) do
            create(
              :triage,
              patient: consent.patient,
              programme: consent.programme,
              organisation: consent.organisation
            )
          end

          it "doesn't invalidate the consent" do
            expect { close! }.not_to(change { consent.reload.invalidated? })
          end

          it "doesn't invalidate the triage" do
            expect { close! }.not_to(change { triage.reload.invalidated? })
          end
        end
      end

      context "when a patient has already had the vaccine" do
        let!(:already_had_patient) { create(:patient, session:, programme:) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient: already_had_patient,
            programme:
          )
        end

        it "doesn't add the patient to the generic clinic session" do
          expect(generic_clinic_session.patients).to be_empty
          close!
          expect(generic_clinic_session.patients).to be_empty
        end
      end
    end
  end

  describe "#open_for_consent?" do
    subject(:open_for_consent?) { session.open_for_consent? }

    context "without a close consent period" do
      let(:session) { create(:session, date: nil) }

      it { should be(false) }
    end

    context "when the consent period closes today" do
      let(:session) { create(:session, date: Date.tomorrow) }

      it { should be(true) }
    end

    context "when the consent period closes tomorrow" do
      let(:session) { create(:session, date: Date.tomorrow + 1.day) }

      it { should be(true) }
    end

    context "when the consent period closed yesterday" do
      let(:session) { create(:session, date: Date.current) }

      it { should be(false) }
    end
  end
end
