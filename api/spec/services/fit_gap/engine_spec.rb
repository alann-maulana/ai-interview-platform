# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FitGap::Engine, type: :service do
  # ── Fake Gemini client that returns a canned narrative ──────────────────────
  let(:fake_gemini) do
    double('GeminiClient').tap do |client|
      allow(client).to receive(:generate_content).and_return(
        { 'culture_narrative' => 'Strong cultural fit.', 'overall_narrative' => 'Recommend for hire.' }
      )
    end
  end

  # ── Shared setup ────────────────────────────────────────────────────────────
  let(:assessment)      { create(:assessment) }
  let(:session)         { create(:session, assessment: assessment) }
  let(:portfolio)       { create(:portfolio, session: session) }
  let(:vacancy)         { create(:vacancy) }
  let!(:vacancy_skill)  { create(:vacancy_skill, vacancy: vacancy, skill_label: 'Ruby on Rails', expected_level: 3) }

  let(:engine) { described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: fake_gemini) }

  # ─────────────────────────────────────────────────────────────────────────────
  describe '#call — skill_comparisons shape' do
    context 'when the candidate has a matching portfolio skill (no override)' do
      let!(:portfolio_skill) { create(:portfolio_skill, portfolio: portfolio, skill_label: 'Ruby on Rails', ai_level: 3) }

      it 'returns result: match' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison['result']).to eq('match')
      end

      it 'returns expected_level (not required_level) in every comparison' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison).to have_key('expected_level')
        expect(comparison['expected_level']).to eq(3)
        # Ensure the old (broken) key is not present
        expect(comparison).not_to have_key('required_level')
      end

      it 'returns is_override: false when no assessor override exists' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison['is_override']).to eq(false)
      end

      it 'returns confidence in every comparison row' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison).to have_key('confidence')
        expect(comparison['confidence']).to eq('high')
      end
    end

    # ── P0 SEEDED FAULT TEST — is_override must be sent when override exists ──
    context 'when an assessor override has been applied' do
      let!(:portfolio_skill) { create(:portfolio_skill, portfolio: portfolio, skill_label: 'Ruby on Rails', ai_level: 2) }
      let!(:override)        { create(:assessor_override, portfolio_skill: portfolio_skill, ai_level: 2, override_level: 4) }

      it 'returns is_override: true (P0 fix — seeded fault test target)' do
        report = engine.call
        comparison = report.skill_comparisons.first
        # THIS is the assertion that would have failed before the fix.
        # To run the seeded fault test: comment out `is_override:` in engine.rb → this fails.
        expect(comparison['is_override']).to eq(true)
      end

      it 'uses the override_level (4) not the ai_level (2) for result calculation' do
        report = engine.call
        comparison = report.skill_comparisons.first
        # override_level=4 vs expected_level=3 → exceed
        expect(comparison['result']).to eq('exceed')
        expect(comparison['candidate_level']).to eq(4)
        expect(comparison['delta']).to eq(1)
      end
    end

    context 'when the vacancy skill is not in the portfolio' do
      # No portfolio_skill created → not_assessed

      it 'returns result: not_assessed with nil candidate_level' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison['result']).to eq('not_assessed')
        expect(comparison['candidate_level']).to be_nil
      end

      it 'returns is_override: false for not_assessed skills' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison['is_override']).to eq(false)
      end

      it 'still includes expected_level for not_assessed skills' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison['expected_level']).to eq(3)
      end
    end

    context 'with a skill gap' do
      let!(:portfolio_skill) { create(:portfolio_skill, portfolio: portfolio, skill_label: 'Ruby on Rails', ai_level: 1, ai_confidence: 'low') }

      it 'returns result: gap with negative delta' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison['result']).to eq('gap')
        expect(comparison['delta']).to eq(-2)  # 1 - 3 = -2
      end

      it 'passes through low confidence' do
        report = engine.call
        comparison = report.skill_comparisons.first
        expect(comparison['confidence']).to eq('low')
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe '#call — narrative fallback' do
    let!(:portfolio_skill) { create(:portfolio_skill, portfolio: portfolio, skill_label: 'Ruby on Rails', ai_level: 3) }

    context 'when Gemini narrative call fails' do
      let(:failing_gemini) do
        double('GeminiClient').tap do |client|
          allow(client).to receive(:generate_content).and_raise(StandardError, 'timeout')
        end
      end

      it 'falls back to a rule-based overall_narrative and does not raise' do
        engine_with_fail = described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: failing_gemini)
        report = engine_with_fail.call
        expect(report.overall_narrative).to be_present
        expect(report.culture_narrative).to be_nil
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe '#call — report persistence' do
    let!(:portfolio_skill) { create(:portfolio_skill, portfolio: portfolio, skill_label: 'Ruby on Rails', ai_level: 3) }

    it 'creates a FitGapReport record' do
      expect { engine.call }.to change(FitGapReport, :count).by(1)
    end

    it 'is idempotent — calling twice updates the same record' do
      engine.call
      expect { engine.call }.not_to change(FitGapReport, :count)
    end
  end
end
