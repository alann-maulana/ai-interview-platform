# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name       { "Acme Corp" }
    scheme     { "acme" }
    identifier { "acme" }
    host       { "acme.localhost" }
  end

  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password         { "password123" }
    role             { "user" }

    trait :admin do
      role { "admin" }
    end

    trait :assessor do
      role { "assessor" }
    end
  end

  factory :assessment do
    name           { "Backend Engineer" }
    time_limit_min { 30 }
    language       { "en" }
    created_by     { association(:user).id }
    tenant_id      { 1 }
  end

  factory :assessment_skill do
    association :assessment
    skill_label    { "Ruby on Rails" }
    is_custom      { false }
    expected_level { 3 }
    display_order  { 0 }
    l1_anchor      { "Can read basic Rails code" }
    l2_anchor      { "Builds simple CRUD apps" }
    l3_anchor      { "Designs complex associations and services" }
    l4_anchor      { "Architects multi-tenant Rails systems" }
    l5_anchor      { "Defines Rails best practices org-wide" }
  end

  factory :vacancy do
    role_title              { "Backend Engineer" }
    culture_dimensions      { "Collaborative, data-driven" }
    competency_expectations { "Strong Ruby skills required" }
    created_by              { association(:user).id }
    tenant_id               { 1 }
  end

  factory :vacancy_skill do
    association :vacancy
    skill_label    { "Ruby on Rails" }
    expected_level { 3 }
  end

  factory :session do
    association :assessment
    invite_token { SecureRandom.hex(32) }
    status       { "ended" }
    tenant_id    { 1 }
    started_at   { 1.hour.ago }
    ended_at     { Time.current }
    duration_seconds { 1800 }
  end

  factory :portfolio do
    association :session
    generation_status { "complete" }
    generated_at      { Time.current }
  end

  factory :portfolio_skill do
    association :portfolio
    skill_label        { "Ruby on Rails" }
    is_discovered      { false }
    ai_level           { 3 }
    ai_confidence      { "high" }
    evidence           { ["I use ActiveRecord associations heavily", "I've built multi-tenant systems"] }
    competency_summary { "Solid Rails practitioner who handles complex associations confidently." }
  end

  factory :assessor_override do
    association :portfolio_skill
    ai_level       { 3 }
    override_level { 4 }
    assessor_notes { "Candidate demonstrated deeper knowledge during live Q&A" }
    overridden_by  { 1 }
    overridden_at  { Time.current }
  end

  factory :fit_gap_report do
    association :portfolio
    association :vacancy
    skill_comparisons { [] }
    culture_narrative { "Strong culture fit." }
    overall_narrative { "Recommend for hire." }
    generated_at      { Time.current }
  end
end
