# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id              :bigint           not null, primary key
#  email           :string           not null
#  name            :string           not null
#  phone           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint           not null
#
# Indexes
#
#  index_teams_on_organisation_id           (organisation_id)
#  index_teams_on_organisation_id_and_name  (organisation_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#

describe Team do
  subject(:team) { build(:team) }

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:phone) }
  end
end
