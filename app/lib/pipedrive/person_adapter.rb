class Pipedrive::PersonAdapter
  PIPEDRIVE_POSTE_ATTRIBUTE_ID = '33a790746f1713d712fe97bcce9ac1ca6374a4d6'
  PIPEDRIVE_ROBOT_ID = '2748449'

  def fetch_people_demandes
    response = self.get_persons_owned_by_user(PIPEDRIVE_ROBOT_ID)
    json = JSON.parse(response.body)

    json['data'].map do |datum|
      {
        person_id: datum['id'],
        nom: datum['name'],
        poste: datum[PIPEDRIVE_POSTE_ATTRIBUTE_ID],
        email: datum.dig('email', 0, 'value'),
        organisation: datum['org_name']
      }
    end
  end

  def update_person_owner(person_id, owner_id)
    params = { owner_id: owner_id }

    self.put_person(person_id, params)
  end
end
