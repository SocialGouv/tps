require 'spec_helper'

describe Gestionnaire, type: :model do
  let(:admin) { create :administrateur }
  let!(:procedure) { create :procedure, :published, administrateur: admin }
  let!(:procedure_2) { create :procedure, :published, administrateur: admin }
  let!(:procedure_3) { create :procedure, :published, administrateur: admin }
  let(:gestionnaire) { create :gestionnaire, administrateurs: [admin] }
  let!(:procedure_assign) { create :assign_to, gestionnaire: gestionnaire, procedure: procedure }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_2
  end

  describe 'follow' do
    let(:dossier) { create :dossier }
    let(:already_followed_dossier) { create :dossier }

    before { gestionnaire.followed_dossiers << already_followed_dossier }

    context 'when a gestionnaire follow a dossier for the first time' do
      before { gestionnaire.follow(dossier) }

      it { expect(gestionnaire.follow?(dossier)).to be true }
    end

    context 'when a gestionnaire follows a dossier already followed' do
      before { gestionnaire.follow(already_followed_dossier) }

      it { expect(gestionnaire.follow?(already_followed_dossier)).to be true }
    end
  end

  describe '#unfollow' do
    let(:already_followed_dossier) { create(:dossier) }
    before { gestionnaire.followed_dossiers << already_followed_dossier }

    context 'when a gestionnaire unfollow a dossier already followed' do
      before do
        gestionnaire.unfollow(already_followed_dossier)
        already_followed_dossier.reload
      end

      it { expect(gestionnaire.follow?(already_followed_dossier)).to be false }
    end
  end

  describe '#follow?' do
    let!(:dossier) { create :dossier, procedure: procedure }

    subject { gestionnaire.follow?(dossier) }

    context 'when gestionnaire follow a dossier' do
      before do
        create :follow, dossier_id: dossier.id, gestionnaire_id: gestionnaire.id
      end

      it { is_expected.to be_truthy }
    end

    context 'when gestionnaire not follow a dossier' do
      it { is_expected.to be_falsey }
    end
  end

  describe "#assign_to_procedure" do
    subject { gestionnaire.assign_to_procedure(procedure_to_assign) }

    context "with a procedure not already assigned" do
      let(:procedure_to_assign) { procedure_3 }

      it { is_expected.to be_truthy }
      it { expect{ subject }.to change(gestionnaire.procedures, :count) }
    end

    context "with an already assigned procedure" do
      let(:procedure_to_assign) { procedure }

      it { is_expected.to be_falsey }
      it { expect{ subject }.not_to change(gestionnaire.procedures, :count) }
    end
  end

  describe "#remove_from_procedure" do
    subject { gestionnaire.remove_from_procedure(procedure_to_remove) }

    context "with an assigned procedure" do
      let(:procedure_to_remove) { procedure }
      let!(:procedure_presentation) { procedure_assign.procedure_presentation }

      it { is_expected.to be_truthy }

      describe "consequences" do
        before do
          procedure_assign.build_procedure_presentation
          procedure_assign.save
          subject
        end

        it "removes the assign_to and procedure_presentation" do
          expect(AssignTo.where(id: procedure_assign).count).to eq(0)
          expect(ProcedurePresentation.where(assign_to_id: procedure_assign.id).count).to eq(0)
        end
      end
    end

    context "with an already unassigned procedure" do
      let(:procedure_to_remove) { procedure_3 }

      it { is_expected.to be_falsey }
    end
  end

  context 'unified login' do
    it 'syncs credentials to associated user' do
      gestionnaire = create(:gestionnaire)
      user = create(:user, email: gestionnaire.email)

      gestionnaire.update(email: 'whoami@plop.com', password: 'super secret')

      user.reload
      expect(user.email).to eq('whoami@plop.com')
      expect(user.valid_password?('super secret')).to be(true)
    end

    it 'syncs credentials to associated administrateur' do
      gestionnaire = create(:gestionnaire)
      admin = create(:administrateur, email: gestionnaire.email)

      gestionnaire.update(email: 'whoami@plop.com', password: 'super secret')

      admin.reload
      expect(admin.email).to eq('whoami@plop.com')
      expect(admin.valid_password?('super secret')).to be(true)
    end
  end

  describe 'last_week_overview' do
    let!(:gestionnaire2) { create(:gestionnaire) }
    subject { gestionnaire2.last_week_overview }
    let(:friday) { DateTime.new(2017, 5, 12) }
    let(:monday) { DateTime.now.beginning_of_week }

    before { Timecop.freeze(friday) }
    after { Timecop.return }

    context 'when no procedure published was active last week' do
      let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire2], libelle: 'procedure', published_at: Time.now) }
      context 'when the gestionnaire has no notifications' do
        it { is_expected.to eq(nil) }
      end
    end

    context 'when a procedure published was active' do
      let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire2], libelle: 'procedure', published_at: Time.now) }
      let(:procedure_overview) { double('procedure_overview', 'had_some_activities?'.to_sym => true) }

      before :each do
        expect_any_instance_of(Procedure).to receive(:procedure_overview).and_return(procedure_overview)
      end

      it { expect(gestionnaire2.last_week_overview[:procedure_overviews]).to match([procedure_overview]) }
    end

    context 'when a procedure not published was active with no notifications' do
      let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire2], libelle: 'procedure', published_at: nil) }
      let(:procedure_overview) { double('procedure_overview', 'had_some_activities?'.to_sym => true) }

      before :each do
        allow_any_instance_of(Procedure).to receive(:procedure_overview).and_return(procedure_overview)
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe '#can_view_dossier?' do
    subject{ gestionnaire.can_view_dossier?(dossier.id) }

    context 'when gestionnaire is assigned on dossier' do
      let!(:dossier){ create(:dossier, procedure: procedure, state: 'en_instruction') }

      it { expect(subject).to be true }
    end

    context 'when gestionnaire is invited on dossier' do
      let(:dossier){ create(:dossier) }
      let!(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire) }

      it { expect(subject).to be true }
    end

    context 'when gestionnaire is neither assigned nor invited on dossier' do
      let(:dossier){ create(:dossier) }

      it { expect(subject).to be false }
    end
  end

  describe "procedure_presentation_for_procedure_id" do
    let!(:pp) { ProcedurePresentation.create(assign_to: procedure_assign) }

    it { expect(gestionnaire.procedure_presentation_for_procedure_id(procedure.id)).to eq(pp) }
    it { expect(gestionnaire.procedure_presentation_for_procedure_id(procedure_2.id).persisted?).to be_falsey }
  end

  describe '#notifications_for_dossier' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }

    subject { gestionnaire.notifications_for_dossier(dossier) }

    context 'when the gestionnaire has just followed the dossier' do
      it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ demande: true, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on a piece jusitificative' do
      before { dossier.pieces_justificatives << create(:piece_justificative, :contrat) }

      it { is_expected.to match({ demande: true, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on private champs' do
      before { dossier.champs_private.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ demande: false, annotations_privees: true, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on avis' do
      before { create(:avis, dossier: dossier) }

      it { is_expected.to match({ demande: false, annotations_privees: false, avis: true, messagerie: false }) }
    end

    context 'messagerie' do
      context 'when there is a new commentaire' do
        before { create(:commentaire, dossier: dossier, email: 'a@b.com') }

        it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: true }) }
      end

      context 'when there is a new commentaire issued by tps' do
        before { create(:commentaire, dossier: dossier, email: 'contact@demarches-simplifiees.fr') }

        it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: false }) }
      end
    end
  end

  describe '#notification_for_procedure' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }
    let(:procedure) { dossier.procedure }
    let!(:gestionnaire_2) { create(:gestionnaire, procedures: [procedure]) }

    let!(:dossier_on_procedure_2) { create(:dossier, :followed, state: 'en_construction') }
    let!(:gestionnaire_on_procedure_2) { dossier_on_procedure_2.follows.first.gestionnaire }

    before do
      gestionnaire_2.followed_dossiers << dossier
    end

    subject { gestionnaire.notifications_for_procedure(procedure) }

    context 'when the gestionnaire has just followed the dossier' do
      it { is_expected.to match([]) }
    end

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match([dossier.id]) }
      it { expect(gestionnaire_2.notifications_for_procedure(procedure)).to match([dossier.id]) }
      it { expect(gestionnaire_on_procedure_2.notifications_for_procedure(procedure)).to match([]) }

      context 'and there is a modification on private champs' do
        before { dossier.champs_private.first.update_attribute('value', 'toto') }

        it { is_expected.to match([dossier.id]) }
      end

      context 'when gestionnaire update it s public champs last seen' do
        let(:follow) { gestionnaire.follows.find_by(dossier: dossier) }

        before { follow.update_attribute('demande_seen_at', DateTime.now) }

        it { is_expected.to match([]) }
        it { expect(gestionnaire_2.notifications_for_procedure(procedure)).to match([dossier.id]) }
      end
    end

    context 'when there is a modification on a piece justificative' do
      before { dossier.pieces_justificatives << create(:piece_justificative, :contrat) }

      it { is_expected.to match([dossier.id]) }
    end

    context 'when there is a modification on public champs on a followed dossier from another procedure' do
      before { dossier_on_procedure_2.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match([]) }
    end

    context 'when there is a modification on private champs' do
      before { dossier.champs_private.first.update_attribute('value', 'toto') }

      it { is_expected.to match([dossier.id]) }
    end

    context 'when there is a modification on avis' do
      before { create(:avis, dossier: dossier) }

      it { is_expected.to match([dossier.id]) }
    end

    context 'the messagerie' do
      context 'when there is a new commentaire' do
        before { create(:commentaire, dossier: dossier, email: 'a@b.com') }

        it { is_expected.to match([dossier.id]) }
      end

      context 'when there is a new commentaire issued by tps' do
        before { create(:commentaire, dossier: dossier, email: 'contact@demarches-simplifiees.fr') }

        it { is_expected.to match([]) }
      end
    end
  end

  describe '#notifications_per_procedure' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }
    let(:procedure) { dossier.procedure }

    subject { gestionnaire.notifications_per_procedure }

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ procedure.id => 1 }) }
    end
  end

  describe '#mark_tab_as_seen' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }
    let(:freeze_date) { DateTime.parse('12/12/2012') }

    context 'when demande is acknowledged' do
      let(:follow) { gestionnaire.follows.find_by(dossier: dossier) }

      before do
        Timecop.freeze(freeze_date)
        gestionnaire.mark_tab_as_seen(dossier, :demande)
      end
      after { Timecop.return }

      it { expect(follow.demande_seen_at).to eq(freeze_date) }
    end
  end
end
