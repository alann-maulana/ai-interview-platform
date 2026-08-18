# frozen_string_literal: true

require 'rails_helper'

# ── Request spec: asserts the exact shape of skill_comparisons items ──────────
# This is the contract test that would have caught the required_level vs
# expected_level mismatch (P0 bug) if it had existed.
RSpec.describe 'GET /api/v1/portfolios/:id/fitgap/:vacancy_id', type: :request do
  let(:organization) { create(:organization) }
  let(:user)         { create(:user, :assessor) }

  # Stub the tenant resolution so require_tenant! passes
  before do
    RequestStore.store[:organization] = organization
    allow(Current).to receive(:organization).and_return(organization)
    allow(Current).to receive(:tenant_id).and_return(1)
  end

  # Build JWT token for the assessor user
  let(:token) do
    payload = { user_id: user.id, tenant_id: 1, role: 'assessor', exp: 1.hour.from_now.to_i }
    JWT.encode(payload, Rails.application.credentials.secret_key_base || 'rakamin-api', 'HS256')
  end

  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  let(:assessment)     { create(:assessment) }
  let(:session_record) { create(:session, assessment: assessment) }
  let(:portfolio)      { create(:portfolio, session: session_record) }
  let(:vacancy)        { create(:vacancy) }

  let!(:vacancy_skill) do
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'Ruby on Rails', expected_level: 3)
  end

  let!(:portfolio_skill) do
    create(:portfolio_skill, portfolio: portfolio, skill_label: 'Ruby on Rails',
           ai_level: 3, ai_confidence: 'high')
  end

  let!(:fit_gap_report) do
    # Pre-create a report with the correct shape from FitGap::Engine
    create(:fit_gap_report,
      portfolio: portfolio,
      vacancy:   vacancy,
      skill_comparisons: [
        {
          'skill_label'     => 'Ruby on Rails',
          'skill_id'        => nil,
          'candidate_level' => 3,
          'expected_level'  => 3,
          'result'          => 'match',
          'delta'           => 0,
          'confidence'      => 'high',
          'is_override'     => false
        }
      ]
    )
  end

  describe 'skill_comparisons contract (P0 regression guard)' do
    before { get "/api/v1/portfolios/#{portfolio.id}/fitgap/#{vacancy.id}", headers: headers }

    it 'returns HTTP 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns skill_comparisons array' do
      json = JSON.parse(response.body)
      expect(json['report']['skill_comparisons']).to be_an(Array)
    end

    it 'each comparison has expected_level (not required_level) — P0 contract test' do
      json = JSON.parse(response.body)
      comparison = json['report']['skill_comparisons'].first
      # These two assertions are the core regression guard.
      expect(comparison).to have_key('expected_level')
      expect(comparison).not_to have_key('required_level')
    end

    it 'each comparison has is_override field' do
      json = JSON.parse(response.body)
      comparison = json['report']['skill_comparisons'].first
      expect(comparison).to have_key('is_override')
    end

    it 'each comparison has confidence field' do
      json = JSON.parse(response.body)
      comparison = json['report']['skill_comparisons'].first
      expect(comparison).to have_key('confidence')
    end

    it 'each comparison has result field with valid value' do
      json = JSON.parse(response.body)
      comparison = json['report']['skill_comparisons'].first
      expect(%w[match gap exceed not_assessed]).to include(comparison['result'])
    end
  end
end
