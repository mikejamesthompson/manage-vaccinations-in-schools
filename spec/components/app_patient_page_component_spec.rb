# frozen_string_literal: true

describe AppPatientPageComponent do
  subject(:rendered) { render_inline(component) }

  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(AppSimpleStatusBannerComponent).to receive(
      :new_session_patient_triages_path
    ).and_return("/session/patient/triage/new")
    # rubocop:enable RSpec/AnyInstance
    stub_authorization(allowed: true)
  end

  let(:programme) { create(:programme, :hpv) }
  let(:vaccine) { programme.vaccines.first }

  let(:component) do
    described_class.new(
      patient_session:,
      vaccination_record: VaccinationRecord.new(patient_session:),
      section: "triage",
      tab: "needed",
      triage: nil
    )
  end

  context "session in progress, patient in triage" do
    before { Flipper.enable(:release_1b) }
    after { Flipper.disable(:release_1b) }

    let(:patient_session) do
      create(
        :patient_session,
        :consent_given_triage_needed,
        :session_in_progress,
        programme:
      )
    end

    it { should have_css(".nhsuk-card__heading", text: "Child details") }
    it { should have_css(".nhsuk-card__heading", text: "Consent") }
    it { should_not have_css(".nhsuk-card__heading", text: "Triage notes") }

    it "shows the triage form" do
      expect(rendered).to have_selector(
        :heading,
        text: "Is it safe to vaccinate"
      )
    end

    it "does not show the vaccination form" do
      expect(rendered).not_to have_css(
        ".nhsuk-card",
        text: "Did they get the HPV vaccine?"
      )
    end

    it { should have_css("a", text: "Assess Gillick competence") }

    context "user is not allowed to triage or vaccinate" do
      before { stub_authorization(allowed: false) }

      it "does not show the triage form" do
        expect(rendered).not_to have_css(
          ".nhsuk-card__heading",
          text: "Is it safe to vaccinate"
        )
      end
    end
  end

  context "session closed, patient in triage" do
    before { Flipper.enable(:release_1b) }
    after { Flipper.disable(:release_1b) }

    let(:patient_session) do
      create(
        :patient_session,
        :consent_given_triage_needed,
        :session_closed,
        programme:
      )
    end

    it "does not show the triage form" do
      expect(rendered).not_to have_selector(
        :heading,
        text: "Is it safe to vaccinate"
      )
    end

    it "does not show the vaccination form" do
      expect(rendered).not_to have_css(
        ".nhsuk-card",
        text: "Did they get the HPV vaccine?"
      )
    end
  end

  context "session in progress, patient ready to vaccinate" do
    before { Flipper.enable(:release_1b) }
    after { Flipper.disable(:release_1b) }

    let(:patient_session) do
      create(
        :patient_session,
        :triaged_ready_to_vaccinate,
        :session_in_progress,
        programme:
      )
    end

    it { should have_css(".nhsuk-card__heading", text: "Child details") }
    it { should have_css(".nhsuk-card__heading", text: "Consent") }
    it { should have_css(".nhsuk-card__heading", text: "Triage notes") }

    it "does not show the triage form" do
      expect(rendered).not_to have_css(
        ".nhsuk-card__heading",
        text: "Is it safe to vaccinate"
      )
    end

    it "shows the vaccination form" do
      expect(rendered).to have_css(
        ".nhsuk-card__heading",
        text: "Did they get the HPV vaccine?"
      )
    end

    context "user is not allowed to triage or vaccinate" do
      before { stub_authorization(allowed: false) }

      it "does not show the vaccination form" do
        expect(rendered).not_to have_css(
          ".nhsuk-card__heading",
          text: "Did they get the HPV vaccine?"
        )
      end
    end
  end

  context "session in progress, patient without consent, no Gillick assessment" do
    before { Flipper.enable(:release_1b) }
    after { Flipper.disable(:release_1b) }

    let(:patient_session) do
      create(:patient_session, :session_in_progress, programme:)
    end

    context "nurse user" do
      before { stub_authorization(allowed: true) }

      it { should have_css("a", text: "Assess Gillick competence") }
    end

    context "admin user" do
      before { stub_authorization(allowed: false) }

      it { should_not have_css("a", text: "Assess Gillick competence") }
    end
  end

  context "session in progress, patient without consent, Gillick assessment" do
    let(:patient_session) do
      create(
        :patient_session,
        :session_in_progress,
        :gillick_competent,
        programme:
      )
    end

    context "nurse user" do
      before { stub_authorization(allowed: true) }

      it { should have_css("a", text: "Edit Gillick competence") }

      it "shows the Gillick assessment" do
        expect(rendered).to have_css(
          ".nhsuk-card__heading",
          text: "Gillick assessment"
        )
      end
    end

    context "admin user" do
      before { stub_authorization(allowed: false) }

      it { should_not have_css("a", text: "Edit Gillick competence") }
    end
  end
end
