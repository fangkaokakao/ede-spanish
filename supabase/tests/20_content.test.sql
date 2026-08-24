-- ============================================================================
-- 20_content.test.sql — content integrity + measurement invariants.
-- Guards the Spain-Spanish, pronunciation-consistency and mastery rules so the
-- v1 content defects cannot silently return.
-- ============================================================================
begin;
create extension if not exists pgtap;
select plan(18);

-- ---- pronunciation consistency (review items 7 & 8) -----------------------
select is(
  (select count(*)::int from content.learning_objectives
    where code = 'PRE_A1.U1.O4' and can_do_th like '%r %'),
  0, 'C1 the ll objective no longer claims to teach r');

select is(
  (select payload ->> 'target_slug' from content.content_blocks
    where block_type = 'pronunciation_guide'),
  'll_y_yeismo', 'C2 pronunciation_guide points at the ll target, not tap_r');

select is(
  (select payload ->> 'focus' from content.content_blocks
    where block_type = 'pronunciation_guide'),
  'll', 'C3 focus and target name the same skill');

select is(
  (select payload ->> 'pron_target_slug' from content.exercises
    where template_id = 'repeat_speech'),
  'll_y_yeismo', 'C4 the speaking exercise targets the taught skill');

select is(
  (select answer_rules -> 'error_codes' ->> 0 from content.exercises
    where template_id = 'repeat_speech'),
  'PRON.LL_Y', 'C5 the speaking error code matches the taught skill');

-- every seeded exercise error code must exist in the taxonomy
select is(
  (select count(*)::int from content.exercises e,
     lateral jsonb_array_elements_text(coalesce(e.answer_rules->'error_codes','[]'::jsonb)) c
   where not exists (select 1 from content.error_taxonomy t where t.code = c)),
  0, 'C6 every exercise error code exists in the taxonomy');

-- the scored frame must actually contain the sound being taught
select ok(
  (select payload ->> 'scored_frame' from content.exercises
    where template_id = 'repeat_speech') like '%llamo%',
  'C7 the scored frame actually contains the target sound');

-- ---- pronunciation standard (review items 9 & 10) -------------------------
select is(
  (select ipa_phonemic from content.pronunciation_targets where slug='ll_y_yeismo'),
  'ʝ', 'C8 the ll target is the yeista phoneme, not the lateral');

select is(
  (select count(*)::int from content.pronunciation_targets where ipa_phonemic like '%ʎ%'),
  0, 'C9 no /ʎ/ anywhere: we teach yeismo and the audio must agree');

select is(
  (select count(*)::int from content.vocabulary_entries where ipa_phonemic like '%ʎ%'),
  0, 'C10 vocabulary IPA follows the same model as the taught target');

select ok(
  (select ipa_phonemic from content.vocabulary_entries where lemma='llamarse') like '/%/'
  and (select ipa_phonetic from content.vocabulary_entries where lemma='llamarse') like '[%]',
  'C11 phonemic and phonetic transcriptions are distinct and correctly delimited');

-- ---- exercise validation (review items 11 & 12) ---------------------------
select ok(
  assess.check_answer('Me llamo Somchai',
    (select answer_rules from content.exercises where template_id='typed'))
  and assess.check_answer('me llamo Ana',
    (select answer_rules from content.exercises where template_id='typed'))
  and assess.check_answer('Me llamo Fangkao',
    (select answer_rules from content.exercises where template_id='typed')),
  'C12 the name-slot exercise accepts any learner name');

select ok(
  not assess.check_answer('Llamo Somchai',
    (select answer_rules from content.exercises where template_id='typed'))
  and not assess.check_answer('Me llamo',
    (select answer_rules from content.exercises where template_id='typed')),
  'C13 it still rejects a broken frame or a missing name');

-- ---- no false absolutes (review item 14) ----------------------------------
-- A blunt keyword scan for "เสมอ"/"ทุกคำ" produced two false positives on study
-- advice ("always memorise the noun with its article"), which is sound guidance
-- and not a claim about the language. So the rule targets the specific
-- oversimplification SHAPES the style guide forbids, not the adverbs.
select is(
  (select count(*)::int from content.grammar_concepts
    where explain_l1_th || coalesce(explain_l2_th,'') || coalesce(explain_l3_th,'')
          ~ ('(-o (คือ|แปลว่า|เท่ากับ) ?(ฉัน|ผู้ชาย)'
             '|-a (คือ|แปลว่า|เท่ากับ) ?ผู้หญิง'
             '|ทุกคำที่ลงท้ายด้วย'
             '|ser (คือ|=|หมายถึง) ?ถาวร'
             '|estar (คือ|=|หมายถึง) ?ชั่วคราว'
             '|subjuntivo (คือ|=|หมายถึง) ?ความไม่แน่ใจ'
             '|ลำดับคำ[^.]{0,20}อิสระ)')),
  0, 'C14 none of the forbidden oversimplifications appear in seeded grammar');

-- ---- Spain guard ----------------------------------------------------------
select is(
  (select count(*)::int from content.audio_assets where locale <> 'es-ES'),
  0, 'C15 no non-es-ES audio can exist');

-- ---- mastery invariant ----------------------------------------------------
-- Recognition evidence alone can never reach mastery, however many times.
select tests.mk_learner('c@test') as c \gset
select tests.claim_as(:'c'::uuid); set role authenticated;
select learning.start_session('lesson') as sc \gset
reset role;
do $$
declare i int;
begin
  for i in 1..40 loop
    perform learning.record_evidence_internal(
      (select id from auth.users where email='c@test'),
      '33333333-3333-4333-8333-333333333303','recognition',true);
  end loop;
end $$;
select cmp_ok(
  (select p_mastery from learning.objective_mastery
    where objective_id = '33333333-3333-4333-8333-333333333303'),
  '<=', 0.70::numeric,
  'C16 forty correct multiple-choice answers still cap p_mastery at 0.70');

-- Every block that references an exercise by slug must resolve to a published
-- exercise row. Without this the live adapter silently 404s a block while the
-- local fixture works, which is the worst possible failure mode.
select is(
  (select count(*)::int
     from content.content_blocks b,
          lateral (select b.payload ->> 'exercise_slug' as slug) x
    where b.block_type in ('exercise_embed','speaking_prompt')
      and not exists (select 1 from content.exercises e
                       where e.payload ->> 'slug' = x.slug
                         and e.status = 'published')),
  0, 'C17 every exercise slug referenced by a block resolves to a published exercise');

select is(
  (select count(*)::int from content.exercises where payload ->> 'slug' is null),
  0, 'C18 every exercise carries the slug its blocks look it up by');

select * from finish();
rollback;
