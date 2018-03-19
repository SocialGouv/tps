class SIRETService
  def self.fetch(siret, procedure_id)
    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
    entreprise_params = ApiEntreprise::EntrepriseAdapter.new(siret, procedure_id).to_params

    if etablissement_params.present? && entreprise_params.present?
      association_params = ApiEntreprise::RNAAdapter.new(siret, procedure_id).to_params
      exercices_params = ApiEntreprise::ExercicesAdapter.new(siret, procedure_id).to_params

      params = etablissement_params
        .merge(entreprise_params.transform_keys { |k| "entreprise_#{k}" })
        .merge(association_params.transform_keys { |k| "association_#{k}" })
        .merge(exercices_params)

      params
    end
  end
end
