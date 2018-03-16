module Mails
  class ClosedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "closed_mail"
    DISPLAYED_NAME = "Accusé d'acceptation"
    DEFAULT_SUBJECT = 'Votre dossier demarches-simplifiees.fr nº --numéro du dossier-- a été accepté'
    DOSSIER_STATE = 'accepte'

    def self.template_name_for_procedure(procedure)
      template = procedure.attestation_template
      if template.present? && template.activated?
        "mails/closed_mail_with_attestation"
      else
        "mails/closed_mail"
      end
    end
  end
end
