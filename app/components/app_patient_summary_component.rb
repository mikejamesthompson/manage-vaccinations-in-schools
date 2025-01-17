# frozen_string_literal: true

class AppPatientSummaryComponent < ViewComponent::Base
  def initialize(
    patient,
    show_parent_or_guardians: false,
    change_links: {},
    highlight: true
  )
    super

    @patient = patient

    @show_parent_or_guardians = show_parent_or_guardians
    @change_links = change_links
    @highlight = highlight
  end

  def call
    govuk_summary_list(actions: @change_links.present?) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "NHS number" }
        row.with_value { format_nhs_number }
        if (href = @change_links[:nhs_number])
          row.with_action(
            text: "Change",
            href:,
            visually_hidden_text: "NHS number"
          )
        end
      end
      summary_list.with_row do |row|
        row.with_key { "Full name" }
        row.with_value { format_full_name }
      end
      if @patient.has_preferred_name? || @patient.preferred_full_name_changed?
        summary_list.with_row do |row|
          row.with_key { "Known as" }
          row.with_value { format_preferred_full_name }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "Date of birth" }
        row.with_value { format_date_of_birth }
      end
      if @patient.deceased?
        summary_list.with_row do |row|
          row.with_key { "Date of death" }
          row.with_value { format_date_of_death }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "Gender" }
        row.with_value { format_gender_code }
      end
      unless @patient.restricted?
        summary_list.with_row do |row|
          row.with_key { "Address" }
          row.with_value { format_address }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "School" }
        row.with_value { format_school }
      end
      summary_list.with_row do |row|
        row.with_key { "Year group" }
        row.with_value { format_year_group }
      end
      if @show_parent_or_guardians && !@patient.restricted? &&
           @patient.parents.present?
        summary_list.with_row do |row|
          row.with_key do
            "Parent or guardian".pluralize(@patient.parents.count)
          end
          row.with_value { format_parent_or_guardians }
        end
      end
    end
  end

  private

  def format_nhs_number
    highlight_if(
      helpers.patient_nhs_number(@patient),
      @patient.nhs_number_changed?
    )
  end

  def format_full_name
    highlight_if(
      @patient.full_name,
      @patient.given_name_changed? || @patient.family_name_changed?
    )
  end

  def format_preferred_full_name
    highlight_if(
      @patient.preferred_full_name,
      @patient.preferred_full_name_changed?
    )
  end

  def format_date_of_birth
    highlight_if(
      helpers.patient_date_of_birth(@patient),
      @patient.date_of_birth_changed?
    )
  end

  def format_date_of_death
    highlight_if(
      @patient.date_of_death.to_fs(:long),
      @patient.date_of_death_changed?
    )
  end

  def format_gender_code
    highlight_if(
      @patient.gender_code.to_s.humanize,
      @patient.gender_code_changed?
    )
  end

  def format_address
    highlight_if(
      helpers.format_address_multi_line(@patient),
      @patient.address_changed?
    )
  end

  def format_school
    highlight_if(
      helpers.patient_school(@patient),
      @patient.school_id_changed? || @patient.home_educated_changed?
    )
  end

  def format_year_group
    highlight_if(
      helpers.patient_year_group(@patient),
      @patient.cohort_id_changed? || @patient.registration_changed?
    )
  end

  def format_parent_or_guardians
    tag.ul(class: "nhsuk-list") do
      safe_join(
        @patient.parents.map do |parent|
          tag.li do
            [
              parent.label_to(patient: @patient),
              if (email = parent.email).present?
                tag.span(email, class: "nhsuk-u-secondary-text-color")
              end,
              if (phone = parent.phone).present?
                tag.span(phone, class: "nhsuk-u-secondary-text-color")
              end
            ].compact.join(tag.br).html_safe
          end
        end
      )
    end
  end

  def highlight_if(value, condition)
    return value unless @highlight && condition

    tag.span value, class: "app-highlight"
  end
end
