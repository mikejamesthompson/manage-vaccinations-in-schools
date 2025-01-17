# frozen_string_literal: true

module VaccinationsHelper
  def vaccination_date(datetime)
    date = datetime.to_date

    current_date = Time.zone.today

    if date == current_date
      "Today (#{date.to_fs(:long)})"
    elsif date == current_date - 1
      "Yesterday (#{date.to_fs(:long)})"
    else
      date.to_fs(:long)
    end
  end

  def vaccination_delivery_methods_for(vaccine)
    vaccine.available_delivery_methods.map do |m|
      [m, VaccinationRecord.human_enum_name("delivery_methods", m)]
    end
  end

  def vaccination_delivery_sites_for(vaccine)
    vaccine.available_delivery_sites.map do |s|
      [s, VaccinationRecord.human_enum_name("delivery_sites", s)]
    end
  end

  def in_tab_action_needed?(action, _outcome)
    action.in? %i[vaccinate get_consent triage follow_up check_refusal]
  end

  def in_tab_vaccinated?(_action, outcome)
    outcome.in? %i[vaccinated]
  end

  def in_tab_not_vaccinated?(_action, outcome)
    outcome.in? %i[do_not_vaccinate not_vaccinated]
  end

  # rubocop:disable Rails/HelperInstanceVariable
  def draft_vaccinations_back_link_path
    if @draft_vaccination_record.editing?
      wizard_path("confirm")
    elsif current_step?(@draft_vaccination_record.wizard_steps.first.to_s)
      session_patient_path(
        @session,
        @patient,
        section: "vaccinations",
        tab: "vaccinate"
      )
    else
      previous_wizard_path
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
