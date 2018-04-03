require 'spec_helper'

describe AdminController, type: :controller do
  describe '#alert_on_attestation_and_mail_template_inconsistency' do
    let(:admin) { create(:administrateur) }
    let(:procedure) { create(:procedure, administrateur: admin, closed_mail: closed_mail, published_at: published_at) }
    let(:published_at) { nil }

    subject do
      sign_in admin
      @controller.params[:procedure_id] = procedure.id
      controller.retrieve_procedure
      controller.send(:alert_on_attestation_and_mail_template_inconsitency)
      flash.now[:alert]&.first
    end

    context 'when there is no inconsistency' do
      let(:closed_mail) { nil }

      it { is_expected.not_to be_present }
    end

    context 'when there is an active attestation but the closed mail template does not mention it' do
      let(:closed_mail) { create(:closed_mail) }
      let!(:attestation_template) { create(:attestation_template, procedure: procedure, activated: true) }

      it { is_expected.to be_present }
      it { is_expected.to include("Cette procédure comporte une attestation, mais l’accusé d’acceptation ne la mentionne pas") }
      it { is_expected.to include(edit_admin_procedure_mail_template_path(procedure, Mails::ClosedMail::SLUG)) }

      context 'when the procedure has been published, the attestation cannot be deactivated' do
        let(:published_at) { Time.now }

        it { expect(procedure.locked?).to be_truthy }
        it { is_expected.not_to include(edit_admin_procedure_attestation_template_path(procedure)) }
      end

      context 'when the procedure is still a draft' do
        it { expect(procedure.locked?).to be_falsey }
        it { is_expected.to include(edit_admin_procedure_attestation_template_path(procedure)) }
      end
    end

    context 'when there is no active attestation but the closed mail template mentions one' do
      let(:closed_mail) { create(:closed_mail, body: '--lien attestation--') }

      it { is_expected.to be_present }
      it { is_expected.to include("Cette procédure ne comporte pas d’attestation, mais l’accusé d’acceptation en mentionne une") }
      it { is_expected.to include(edit_admin_procedure_attestation_template_path(procedure)) }
      it { is_expected.to include(edit_admin_procedure_mail_template_path(procedure, Mails::ClosedMail::SLUG)) }
    end
  end
end
