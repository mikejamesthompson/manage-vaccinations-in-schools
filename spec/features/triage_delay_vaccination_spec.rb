require "rails_helper"

RSpec.describe "Triage" do
  scenario "delay vaccination" do
    given_a_campaign_with_a_running_session
    and_i_am_signed_in
    when_i_go_to_the_triage_page

    when_i_click_on_a_patient
    and_i_enter_a_note_and_delay_vaccination
    then_i_see_an_alert_saying_the_record_was_saved

    when_i_go_to_the_triage_completed_tab
    then_i_see_the_patient

    when_i_access_the_record_vaccinations_area
    then_i_see_the_patient_in_the_vaccinate_later_tab

    when_i_view_the_child_record
    then_they_should_have_the_status_banner_delay_vaccination
    and_i_am_able_to_record_a_vaccination
  end

  def given_a_campaign_with_a_running_session
    @team = create(:team, :with_one_nurse, :with_one_location)
    campaign = create(:campaign, :hpv, team: @team)
    @school = @team.locations.first
    session =
      create(:session, campaign:, location: @school, date: Time.zone.today)
    @patient =
      create(
        :patient_with_consent_given_triage_needed,
        session:,
        location: session.location
      )
  end

  def and_i_am_signed_in
    sign_in @team.users.first
  end

  def when_i_go_to_the_triage_page
    visit "/dashboard"
    click_link "School sessions", match: :first
    click_link @school.name
    click_link "Triage health questions"
  end

  def when_i_click_on_a_patient
    click_link @patient.full_name
  end

  def and_i_enter_a_note_and_delay_vaccination
    fill_in "Triage notes (optional)", with: "Delaying vaccination for 2 weeks"
    choose "No, delay vaccination to a later date"
    click_button "Save triage"
  end

  def then_i_see_an_alert_saying_the_record_was_saved
    expect(page).to have_alert(
      "Success",
      text: "Record saved for #{@patient.full_name}"
    )
  end

  def when_i_go_to_the_triage_completed_tab
    click_link "Triage completed"
  end

  def then_i_see_the_patient
    within "div#triage-completed" do
      expect(page).to have_content(@patient.full_name)
    end
  end

  def when_i_access_the_record_vaccinations_area
    click_on @school.name, match: :first
    click_on "Record vaccinations"
  end

  def then_i_see_the_patient_in_the_vaccinate_later_tab
    within "div#vaccinate-later" do
      expect(page).to have_content(@patient.full_name)
    end
  end

  def when_i_view_the_child_record
    click_link @patient.full_name
  end

  def then_they_should_have_the_status_banner_delay_vaccination
    expect(page).to have_content("Delay vaccination to a later date")
  end

  def and_i_am_able_to_record_a_vaccination
    choose "Yes, they got the HPV vaccine"
  end
end