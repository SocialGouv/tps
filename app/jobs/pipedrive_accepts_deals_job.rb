class PipedriveAcceptsDealsJob < ApplicationJob
  def perform(person_id, owner_id, stage_id)
    PipedriveService.accept_deals_from_person(person_id, owner_id, stage_id)
  end
end
