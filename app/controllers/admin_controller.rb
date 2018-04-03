class AdminController < ApplicationController
  before_action :authenticate_administrateur!

  def index
    redirect_to (admin_procedures_path)
  end

  def retrieve_procedure
    id = params[:procedure_id] || params[:id]

    @procedure = current_administrateur.procedures.find(id)

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inexistante'
    redirect_to admin_procedures_path, status: 404
  end

  def procedure_locked?
    if @procedure.locked?
      flash.alert = 'Procédure verrouillée'
      redirect_to admin_procedure_path(id: @procedure.id)
    end
  end

  private

  def alert_on_attestation_and_mail_template_inconsitency
    state = @procedure.closed_mail_template_attestation_inconsistency_state

    if state.present?
      edit_mail_path = edit_admin_procedure_mail_template_path(@procedure, Mails::ClosedMail::SLUG)
      edit_attestation_path = edit_admin_procedure_attestation_template_path(@procedure)

      case state
      when :missing_tag
        alert = "Cette procédure comporte une attestation, mais l’accusé d’acceptation ne la mentionne pas : "
        if !@procedure.locked?
          alert += "<a href='#{edit_attestation_path}'>désactivez l’attestation</a> ou "
        end
        alert += " <a href='#{edit_mail_path}'>ajoutez la balise</a> --lien attestation-- à l’accusé d’acceptation"
      when :extraneous_tag
        alert = "Cette procédure ne comporte pas d’attestation, mais l’accusé d’acceptation en mentionne une : <a href='#{edit_attestation_path}'>activez l’attestation</a> ou <a href='#{edit_mail_path}'>enlevez la balise</a> --lien attestation-- de l’accusé d’acceptation"
      end

      flash.now[:alert] ||= []
      flash.now[:alert] << alert
    end
  end
end
