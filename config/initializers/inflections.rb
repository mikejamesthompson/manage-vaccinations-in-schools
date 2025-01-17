# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "API"
  inflect.acronym "CIS2"
  inflect.acronym "CSRF"
  inflect.acronym "CSV"
  inflect.acronym "DPS"
  inflect.acronym "FHIR"
  inflect.acronym "MESH"
  inflect.acronym "NHS"
  inflect.acronym "ODS"
  inflect.acronym "PDS"
  inflect.acronym "OAuth2"
  inflect.acronym "OpenID"
  inflect.acronym "JWKS"

  inflect.irregular "batch", "batches"
  inflect.irregular "child", "children"
end
