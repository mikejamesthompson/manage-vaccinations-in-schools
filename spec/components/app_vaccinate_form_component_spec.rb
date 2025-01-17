# frozen_string_literal: true

describe AppVaccinateFormComponent do
  subject(:rendered) { render_inline(component) }

  let(:heading) { "A Heading" }
  let(:body) { "A Body" }
  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, :today, programme:) }
  let(:vaccine) { programme.vaccines.first }
  let(:patient_session) do
    create(
      :patient_session,
      :consent_given_triage_not_needed,
      programme:,
      session:
    )
  end
  let(:vaccination_record) { VaccinationRecord.new(patient_session:) }

  let(:component) do
    described_class.new(vaccination_record, section: "vaccinate", tab: "needed")
  end

  it { should have_css(".nhsuk-card") }

  it "has the correct heading" do
    expect(subject).to have_css(
      "h2.nhsuk-card__heading",
      text: "Did they get the HPV vaccine?"
    )
  end

  it { should have_field("Yes, they got the HPV vaccine") }
  it { should have_field("No, they did not get it") }

  describe "#render?" do
    subject(:render) { component.render? }

    context "patient is not ready for vaccination" do
      before do
        allow(patient_session).to receive(:next_step).and_return(:triage)
      end

      context "session is in progress" do
        let(:session) { create(:session, :today, programme:) }

        it { should be_falsey }
      end

      context "session is in the future" do
        let(:session) { create(:session, :scheduled, programme:) }

        it { should be_falsey }
      end
    end

    context "patient is ready for vaccination" do
      before do
        allow(patient_session).to receive(:next_step).and_return(:vaccinate)
      end

      context "session is progress" do
        let(:session) { create(:session, :today, programme:) }

        it { should be_truthy }
      end

      context "session is in the future" do
        let(:session) { create(:session, :scheduled, programme:) }

        it { should be_falsey }
      end
    end
  end
end
