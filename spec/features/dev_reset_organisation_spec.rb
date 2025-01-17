# frozen_string_literal: true

describe "Dev endpoint to reset a organisation" do
  before { Flipper.enable(:dev_tools) }
  after { Flipper.disable(:dev_tools) }

  scenario "Resetting a organisation deletes all associated data" do
    given_an_example_programme_exists
    and_patients_have_been_imported
    and_vaccination_records_have_been_imported

    then_all_associated_data_is_deleted_when_i_reset_the_organisation
  end

  def given_an_example_programme_exists
    @programme = create(:programme, :hpv_all_vaccines)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])

    @programme.vaccines.each do |vaccine|
      create_list(:batch, 4, organisation: @organisation, vaccine:)
    end

    @organisation.update!(ods_code: "R1L") # to match valid_hpv.csv
    create(:location, :school, urn: "123456", organisation: @organisation) # to match cohort_import/valid.csv
    create(:location, :school, urn: "110158", organisation: @organisation) # to match valid_hpv.csv
    @user = @organisation.users.first
  end

  def and_patients_have_been_imported
    sign_in @user
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Cohort"
    click_on "Import child records"
    attach_file("cohort_import[csv]", "spec/fixtures/cohort_import/valid.csv")
    click_on "Continue"

    expect(@organisation.cohorts.flat_map(&:patients).size).to eq(3)
    expect(
      @organisation.cohorts.flat_map(&:patients).flat_map(&:parents).size
    ).to eq(3)
  end

  def and_vaccination_records_have_been_imported
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations", match: :first
    click_on "Import vaccination records"
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"

    expect(VaccinationRecord.count).to eq(11)
  end

  def then_all_associated_data_is_deleted_when_i_reset_the_organisation
    expect { visit "/reset/r1l" }.to(
      change(Patient, :count)
        .by(-3)
        .and(change(Cohort, :count).by(-1))
        .and(change(Parent, :count).by(-3))
        .and(change(VaccinationRecord, :count).by(-11))
        .and(change(ImmunisationImport, :count).by(-1))
        .and(change(CohortImport, :count).by(-1))
    )
  end
end
