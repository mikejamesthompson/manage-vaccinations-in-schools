# frozen_string_literal: true

describe AppConsentComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(patient_session:, section: "triage", tab: "needed")
  end

  let(:consent) { patient_session.consents.first }
  let(:relation) { consent.parent_relationship.label }

  context "consent is not present" do
    let(:patient_session) { create(:patient_session) }

    it { should_not have_css("p.app-status", text: "Consent (given|refused)") }
    it { should_not have_css("details", text: /Consent (given|refused) by/) }
    it { should_not have_css("details", text: "Responses to health questions") }
    it { should have_css("p", text: "No requests have been sent.") }

    context "in release 1b" do
      before { Flipper.enable(:release_1b) }
      after { Flipper.disable(:release_1b) }

      it { should have_css("button", text: "Get consent") }
    end
  end

  context "consent is not present and session is not in progress" do
    let(:patient_session) do
      create(:patient_session, session: create(:session, :scheduled))
    end

    it { should_not have_css("button", text: "Assess Gillick competence") }
  end

  context "consent is refused" do
    let(:patient_session) { create(:patient_session, :consent_refused) }

    let(:summary) do
      "Consent refused by #{consent.parent.full_name} (#{relation})"
    end

    it { should have_css("p.app-status", text: "Refused") }

    it { should have_css("table tr", text: /#{consent.parent.full_name}/) }
    it { should have_css("table tr", text: /#{relation}/) }

    it "displays the response" do
      expect(subject).to have_css("table tr", text: /Consent refused/)
    end

    it { should_not have_css("details", text: "Responses to health questions") }
  end

  context "consent is given" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_needed)
    end

    let(:summary) do
      "Consent given by #{consent.parent.full_name} (#{relation})"
    end

    it { should have_css("p.app-status", text: "Given") }

    it { should_not have_css("a", text: "Contact #{consent.parent.full_name}") }
  end
end
