# frozen_string_literal: true

describe "Parental consent school" do
  scenario "Child attending a clinic goes to a school" do
    given_an_hpv_programme_is_underway

    when_i_go_to_the_consent_form
    and_i_fill_in_my_childs_name_and_birthday
    then_i_see_a_page_asking_if_my_child_is_home_educated

    when_i_choose_no_they_go_to_a_school
    then_i_see_a_page_asking_for_the_childs_school

    when_i_click_continue
    then_i_see_an_error

    when_i_choose_a_school
    then_i_see_the_parent_step
  end

  scenario "Child attending a clinic is home-schooled" do
    given_an_hpv_programme_is_underway

    when_i_go_to_the_consent_form
    and_i_fill_in_my_childs_name_and_birthday
    then_i_see_a_page_asking_if_my_child_is_home_educated

    when_i_click_continue
    then_i_see_an_error

    when_i_choose_yes
    then_i_see_the_parent_step
  end

  scenario "Child attending a clinic is not in education" do
    given_an_hpv_programme_is_underway

    when_i_go_to_the_consent_form
    and_i_fill_in_my_childs_name_and_birthday
    then_i_see_a_page_asking_if_my_child_is_home_educated

    when_i_click_continue
    then_i_see_an_error

    when_i_choose_no_they_are_not_in_education
    then_i_see_the_parent_step
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])

    location = create(:location, :generic_clinic, organisation: @organisation)

    @session =
      create(
        :session,
        :scheduled,
        organisation: @organisation,
        programme: @programme,
        location:
      )

    @child = create(:patient, session: @session)

    create(
      :location,
      :school,
      organisation: @organisation,
      name: "Pilot School"
    )
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def and_i_fill_in_my_childs_name_and_birthday
    click_on "Start now"

    expect(page).to have_content("What is your child’s name?")
    fill_in "First name", with: @child.given_name
    fill_in "Last name", with: @child.family_name
    choose "No" # Do they use a different name in school?
    click_on "Continue"

    expect(page).to have_content("What is your child’s date of birth?")
    fill_in "Day", with: @child.date_of_birth.day
    fill_in "Month", with: @child.date_of_birth.month
    fill_in "Year", with: @child.date_of_birth.year
    click_on "Continue"
  end

  def then_i_see_a_page_asking_if_my_child_is_home_educated
    expect(page).to have_heading("Is your child home-schooled?")
  end

  def when_i_choose_no_they_go_to_a_school
    choose "No, they go to a school"
    click_on "Continue"
  end

  def when_i_choose_no_they_are_not_in_education
    choose "No, they are not in education"
    click_on "Continue"
  end

  def when_i_choose_yes
    choose "Yes"
    click_on "Continue"
  end

  def then_i_see_a_page_asking_for_the_childs_school
    expect(page).to have_heading("What school does your child go to?")
  end

  def when_i_click_continue
    click_on "Continue"
  end

  def then_i_see_an_error
    expect(page).to have_heading "There is a problem"
  end

  def when_i_choose_a_school
    select "Pilot School"
    click_on "Continue"
  end

  def then_i_see_the_parent_step
    expect(page).to have_heading "About you"
  end
end
