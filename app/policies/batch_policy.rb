# frozen_string_literal: true

class BatchPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.unarchived.where(organisation: user.selected_organisation)
    end
  end
end
