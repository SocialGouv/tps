require 'spec_helper'

describe MailTemplateConcern do
  let(:procedure) { create(:procedure) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:dossier2) { create(:dossier, procedure: procedure) }
  let(:initiated_mail) { create(:initiated_mail, procedure: procedure) }

  shared_examples "can replace tokens in template" do
    describe 'with no token to replace' do
      let(:template) { '[demarches-simplifiees.fr] rien à remplacer' }
      it do
        is_expected.to eq("[demarches-simplifiees.fr] rien à remplacer")
      end
    end

    describe 'with one token to replace' do
      let(:template) { '[demarches-simplifiees.fr] Dossier : --numéro du dossier--' }
      it do
        is_expected.to eq("[demarches-simplifiees.fr] Dossier : #{dossier.id}")
      end
    end

    describe 'with multiples tokens to replace' do
      let(:template) { '[demarches-simplifiees.fr] --numéro du dossier-- --libellé procédure-- --lien dossier--' }
      it do
        expected =
          "[demarches-simplifiees.fr] #{dossier.id} #{dossier.procedure.libelle} " +
          "<a target=\"_blank\" href=\"http://localhost:3000/users/dossiers/#{dossier.id}/recapitulatif\">http://localhost:3000/users/dossiers/#{dossier.id}/recapitulatif</a>"

        is_expected.to eq(expected)
      end
    end
  end

  describe '#subject_for_dossier' do
    before { initiated_mail.subject = template }
    subject { initiated_mail.subject_for_dossier(dossier) }

    it_behaves_like "can replace tokens in template"
  end

  describe '#body_for_dossier' do
    before { initiated_mail.body = template }
    subject { initiated_mail.body_for_dossier(dossier) }

    it_behaves_like "can replace tokens in template"
  end

  describe 'tags' do
    describe 'in initiated mail' do
      it "does not treat date de passage en instruction as a tag" do
        expect(initiated_mail.tags).not_to include(include({ libelle: 'date de passage en instruction' }))
      end
    end

    describe 'in received mail' do
      let(:received_mail) { create(:received_mail, procedure: procedure) }

      it "treats date de passage en instruction as a tag" do
        expect(received_mail.tags).to include(include({ libelle: 'date de passage en instruction' }))
      end
    end
  end

  describe '#replace_tags' do
    before { initiated_mail.body = "n --numéro du dossier--" }
    it "avoids side effects" do
      expect(initiated_mail.body_for_dossier(dossier)).to eq("n #{dossier.id}")
      expect(initiated_mail.body_for_dossier(dossier2)).to eq("n #{dossier2.id}")
    end
  end
end
