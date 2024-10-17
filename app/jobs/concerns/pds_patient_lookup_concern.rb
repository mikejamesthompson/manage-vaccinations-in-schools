# frozen_string_literal: true

module PDSPatientLookupConcern
  extend ActiveSupport::Concern

  include NHSAPIConcurrencyConcern

  def find_pds_patient(object)
    query = {
      "family" => object.family_name,
      "given" => object.given_name,
      "birthdate" => "eq#{object.date_of_birth}",
      "address-postalcode" => object.address_postcode,
      "_history" => true # look up previous names and addresses,
    }.compact_blank

    response = NHS::PDS.search_patients(query)
    results = response.body

    return if results["total"].zero?

    results["entry"].first["resource"]
  end
end