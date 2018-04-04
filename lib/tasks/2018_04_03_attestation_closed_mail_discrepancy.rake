namespace :'2018_04_03_attestation_closed_mail_discrepancy' do
  task mail_adminstrators: :environment do
    include Rails.application.routes.url_helpers

    class TaskMailer < ApplicationMailer
      def missing_attestation_tag_email(admin, procedures)
        procedures.sort_by { |p| p.id }
        mail(to: admin.email, subject: subject(procedures), body: body(procedures))
      end

      private

      def subject(procedures)
        if procedures.count == 1
          procedure_ids = "votre procédure nº #{procedures.first.id}"
        else
          procedure_ids = 'vos procédures nº ' + procedures.map{ |p| p.id }.join(', ')
        end
        "demarches-simplifiees.fr – ajoutez un lien vers l’attestation à l’accusé d’acceptation de #{procedure_ids}"
      end

      def body(procedures)
        if procedures.count == 1
          ces_procedures_qui_ont = "la procédure suivante, qui a"
        else
          ces_procedures_qui_ont = "les procédures suivantes, qui ont"
        end

        liste_procedures = procedures.map { |p| "- #{p.id} – #{p.libelle} – #{edit_admin_procedure_mail_template_url(p, Mails::ClosedMail::SLUG)}\n" }.join

        body = <<~HEREDOC
          Bonjour,

          Pour des raisons de confidentialité, les mails d’accusé d’acceptation évoluent.
          Nous n’y attacherons bientôt plus d’attestation en pièce jointe.

          Pour que les usagers puissent continuer à accéder facilement à leurs attestations,
          nous avons introduit la balise --lien attestation--. Celle-ci génère un lien dans
          l’email qui permet à l’usager de télécharger son attestation directement
          depuis son espace sécurisé dans demarches-simplifiees.fr.

          Vous êtes administrateur sur #{ces_procedures_qui_ont} à la fois une attestation
          et un accusé d’acceptation personnalisé. Pour respecter votre rédaction, nous
          n’avons pas ajouté automatiquement de balise --lien attestation-- à votre accusé
          d’acceptation.

          Nous vous invitons à ajouter à votre convenance la balise --lien attestation--
          dans l’accusé d’acceptation afin que vos usagers puissent continuer à accéder
          facilement à leurs attestations dans leurs démarches futures.

          #{liste_procedures}
           --
          L’équipe demarches-simplifiees-fr
        HEREDOC
      end
    end

    Administrateur.includes(:procedures).find_each(batch_size: 10) do |admin|
      procedures = admin.procedures.where(archived_at: nil).select { |p| p.closed_mail_template_attestation_inconsistency_state == :missing_tag }
      if !procedures.empty?
        TaskMailer.missing_attestation_tag_email(admin, procedures).deliver_now!
        print "#{admin.email}\n"
      end
    end
  end
end
