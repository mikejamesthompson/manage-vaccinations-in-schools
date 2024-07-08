# frozen_string_literal: true

require "rails_helper"

describe "Verbal consent" do
  include EmailExpectations

  scenario "Given by a parental contact not on the system" do
    given_i_am_signed_in

    when_i_start_recording_consent_from_a_new_parental_contact
    and_i_record_that_verbal_consent_was_given

    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_i_can_see_the_parents_details_on_the_consent_response
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    campaign = create(:campaign, :hpv, team:)
    @session = create(:session, campaign:, patients_in_session: 1)
    @patient = @session.patients.first

    sign_in team.users.first
  end

  def when_i_start_recording_consent_from_a_new_parental_contact
    visit session_consents_path(@session)
    click_link @patient.full_name
    click_button "Get consent"

    # Who are you trying to get consent from?
    fill_in "Full name", with: "Jane Smith"
    choose "Mum"
    fill_in "Email address", with: "jsmith@example.com"
    fill_in "Phone number", with: "07987654321"
    click_button "Continue"
  end

  def and_i_record_that_verbal_consent_was_given
    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".edit_consent .nhsuk-fieldset")[0].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[1].choose "No"
    find_all(".edit_consent .nhsuk-fieldset")[2].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    # Confirm
    expect(page).to have_content("Check and confirm answers")
    expect(page).to have_content(["Response method", "By phone"].join)
    click_button "Confirm"

    # Back on the consent responses page
    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_i_can_see_the_parents_details_on_the_consent_response
    click_link @patient.full_name
    click_link "Jane Smith"

    expect(page).to have_content("Consent response from Jane Smith")

    expect(page).to have_content(["Name", "Jane Smith"].join)
    expect(page).to have_content(%w[Relationship Mum].join)
    expect(page).to have_content(["Email address", "jsmith@example.com"].join)
    expect(page).to have_content(["Phone number", "07987654321"].join)
  end

  def then_an_email_is_sent_to_the_parent_confirming_their_consent
    expect(sent_emails.count).to eq 1

    expect(sent_emails.last).to be_sent_with_govuk_notify.using_template(
      EMAILS[:parental_consent_confirmation]
    ).to("jsmith@example.com")
  end
end