-- ============================================================================
-- 20260824090400_seed_reference_and_pre_a1.sql  (REWRITTEN — v2)
--
-- v1 CONTENT DEFECTS FIXED HERE
--   D-7   Objective PRE_A1.U1.O4 taught "ll and single r in me llamo".
--         "Me llamo" contains no r. The r objective is removed from this
--         lesson; the tap is introduced later, on words that actually have one.
--   D-8   The pronunciation_guide block pointed at target_slug 'tap_r' while
--         teaching ⟨ll⟩, and the speaking exercise carried PRON.CODA_S, an
--         unrelated category. Objective, target, focus, exercise, error code
--         and audio now all name the same skill.
--   D-9   "ll in Spain is Y" replaced with an explicit, documented standard.
--   D-10  IPA split into phonemic and phonetic and corrected; /ʎ/ removed.
--   D-11  The "use your own name" exercise accepted only "Ploy".
--   D-12  Speaking scored the learner's proper name as pronunciation.
--   D-13  "-o แปลว่า ฉัน" removed — it marks 1sg in this paradigm, it is not
--         a standalone word meaning "I".
--   D-14  False absolutes ("เสมอ", "ทุกคำ", ustedes "wrong in Spain") removed.
--
-- ============================================================================
-- PRONUNCIATION STANDARD DECISION (course-wide, sg-0.2)
--
--   /s/ vs /θ/  : DISTINCIÓN is the productive target.  casa /ˈkasa/ vs
--                 caza /ˈkaθa/.  This is the educated Peninsular norm.
--
--   ⟨ll⟩ vs ⟨y⟩ : YEÍSMO is the productive target. Both are /ʝ/. We do NOT
--                 teach /ʎ/.
--
-- These two look inconsistent and the asymmetry is deliberate, so it is
-- recorded here rather than left for someone to "fix" later: distinción is
-- alive and standard across most of Spain, whereas the ⟨ll⟩–⟨y⟩ contrast has
-- merged for the large majority of speakers, including educated speakers in
-- Madrid and most urban centres. Teaching /ʎ/ would give a Thai learner a
-- production target that most of the people they will speak to do not use, and
-- would contradict our own reference audio.
--
-- Consequence to teach explicitly, but NOT at Pre-A1: under yeísmo, calló and
-- cayó are homophones. Recorded as a recognition note from A2.
--
-- Areas of Spain that retain /ʎ/ (parts of the north, Castilian-Leonese and
-- Catalan/Basque-contact zones) are real and appear later as tagged listening
-- material with is_productive_target = false. They are never a Pre-A1 target.
-- ============================================================================

insert into content.cefr_levels (level, ordinal, name_th, tagline_th, thai_support_ratio, is_available) values
 ('pre_a1', 0, 'เริ่มต้นจากศูนย์', 'เสียงและคำแรกของคุณ',       1.00, true),
 ('a1',     1, 'A1',              'ชีวิตประจำวันเริ่มต้น',      0.85, true),
 ('a2',     2, 'A2',              'จัดการชีวิตในสเปนได้',       0.65, false),
 ('b1',     3, 'B1',              'แสดงความเห็นและเล่าเรื่อง',  0.45, false),
 ('b2',     4, 'B2',              'ถกเถียงและใช้ชีวิตจริง',     0.25, false),
 ('c1',     5, 'C1',              'ความละเอียดและงานอาชีพ',     0.10, false),
 ('c2',     6, 'C2',              'ความแม่นยำระดับเจ้าของภาษา', 0.05, false);

-- ------------------------------------------- Spain lexical policy (as data) --
-- `alternative_status` describes the alternative form's standing IN SPAIN, and
-- must not overstate it. ustedes is perfectly correct Spanish in Spain — it is
-- simply not the default for informal plural address, which is what the
-- validator actually needs to catch.
insert into content.lexicon_policy (spain_form, alternative_form, alternative_status, note_th, severity) values
 ('ordenador','computadora','not_default','ในสเปนคำที่ใช้กันทั่วไปคือ ordenador','error'),
 ('móvil','celular','not_default','ในสเปนใช้ móvil','error'),
 ('coche','carro','false_friend','ในสเปน carro มักหมายถึงรถเข็นหรือเกวียน ไม่ใช่รถยนต์','error'),
 ('zumo','jugo','not_default','น้ำผลไม้ที่สั่งในร้านคือ zumo ส่วน jugo ใช้ได้ในบริบทการทำอาหาร','warn'),
 ('piso','departamento','not_default','ในสเปนนิยมเรียกที่พักว่า piso (apartamento ก็ใช้ได้ ไม่ผิด)','warn'),
 ('conducir','manejar','not_default','ในสเปนใช้ conducir สำหรับการขับรถ','error'),
 ('aparcar','estacionar','not_default','ในสเปนนิยมใช้ aparcar','warn'),
 ('patata','papa','not_default','ในสเปนใช้ patata','error'),
 ('coger','agarrar','not_default','coger เป็นคำธรรมดาที่ใช้กันทั่วไปในสเปน สอนได้ตามปกติ','warn'),
 ('vosotros','ustedes','not_default','ustedes ถูกต้องในสเปนเมื่อพูดสุภาพ แต่เวลาคุยกับเพื่อนหลายคนคนสเปนใช้ vosotros','error');

-- --------------------------------------------------------- error taxonomy --
insert into content.error_taxonomy (code, parent_code, label_th, severity) values
 ('GRAM',null,'ไวยากรณ์','medium'),
 ('GRAM.GEN',       'GRAM','เพศของคำ','high'),
 ('GRAM.GEN.ART',   'GRAM.GEN','เลือก article ไม่ตรงกับเพศของคำนาม','high'),
 ('GRAM.GEN.ADJ',   'GRAM.GEN','คำคุณศัพท์ไม่สอดคล้องกับคำนาม','high'),
 ('GRAM.NUM',       'GRAM','พจน์','medium'),
 ('GRAM.NUM.PLURAL','GRAM.NUM','พหูพจน์ไม่สอดคล้อง','medium'),
 ('GRAM.PERSON',    'GRAM','ผันกริยาผิดบุคคล','high'),
 ('GRAM.ADDRESS',   'GRAM','เลือกรูปการเรียกผู้ฟังไม่เหมาะสม (tú/usted/vosotros/ustedes)','high'),
 ('GRAM.SER_ESTAR', 'GRAM','สับสน ser / estar','high'),
 ('GRAM.PAST',      'GRAM','กาลอดีต','high'),
 ('GRAM.PAST.PERF_IND','GRAM.PAST','สับสน he comido / comí (แบบที่ใช้ในสเปน)','high'),
 ('GRAM.PAST.IND_IMP', 'GRAM.PAST','สับสน indefinido / imperfecto','high'),
 ('GRAM.SUBJ',      'GRAM','การเลือก subjuntivo','high'),
 ('GRAM.PRON',      'GRAM','สรรพนามกรรม','medium'),
 ('GRAM.PREP',      'GRAM','บุพบท','medium'),
 ('GRAM.PREP.POR_PARA','GRAM.PREP','สับสน por / para','medium'),
 ('LEX',null,'คำศัพท์','medium'),
 ('LEX.FALSE_FRIEND','LEX','คำพ้องรูปลวง','medium'),
 ('LEX.LATAM_DEFAULT','LEX','ใช้คำที่เป็นค่าตั้งต้นของละตินอเมริกาแทนคำที่ใช้ในสเปน','medium'),
 ('PRON',null,'การออกเสียง','medium'),
 ('PRON.LL_Y',  'PRON','เสียง ll/y ยังไม่เป็นเสียงเพดาน','high'),
 ('PRON.RR',    'PRON','เสียง rr ยังไม่สั่น','high'),
 ('PRON.TAP_R', 'PRON','เสียง r เดี่ยว','medium'),
 ('PRON.THETA', 'PRON','เสียง /θ/ (z, ce, ci)','medium'),
 ('PRON.CODA_S','PRON','เสียง -s ท้ายพยางค์หายไป','high'),
 ('PRON.CLUSTER','PRON','เติมสระแทรกในกลุ่มพยัญชนะ','high'),
 ('PRON.STRESS','PRON','ลงน้ำหนักเสียงผิดพยางค์','high'),
 ('REG',null,'ระดับภาษา','medium'),
 ('REG.FORMALITY','REG','ใช้ระดับภาษาไม่เหมาะกับสถานการณ์','medium');

-- ------------------------------------------------ pronunciation targets ----
insert into content.pronunciation_targets
 (slug, ipa_phonemic, ipa_phonetic, orthography_rules, articulation_th,
  thai_contrast_th, typical_error_th, minimal_pairs, variation_note_th,
  is_productive_target, cefr_introduced, priority) values

('ll_y_yeismo','ʝ',
 '[{"context":"ระหว่างสระ เช่น me llamo","ipa":"ʝ"},{"context":"ต้นประโยคหรือหลังเสียงนาสิก เช่น Llamo yo","ipa":"ɟ͡ʝ"}]'::jsonb,
 'ตัวอักษร ll และ y (เมื่อทำหน้าที่เป็นพยัญชนะ) ออกเสียงเหมือนกันในมาตรฐานที่คอร์สนี้สอน',
 'ยกกลางลิ้นขึ้นแตะเพดานแข็ง ปล่อยลมผ่านช่องแคบ เสียงก้อง ปลายลิ้นไม่แตะปุ่มเหงือก',
 'ใกล้เคียงเสียง ย ในภาษาไทย แต่ลิ้นแตะเพดานแน่นกว่าเล็กน้อย และไม่ใช่เสียง ล',
 'คนไทยมักออกเป็น ล ตามรูปเขียน ทำให้ llamo กลายเป็น lamo ซึ่งเป็นคนละคำ',
 '[{"a":"lamo","b":"llamo","note_th":"lamo = เลีย / llamo = ฉันเรียก"},{"a":"lave","b":"llave","note_th":"lave = ล้าง / llave = กุญแจ"}]'::jsonb,
 'ในบางพื้นที่ของสเปนยังแยกเสียง ll กับ y อยู่ (/ʎ/) แต่ผู้พูดส่วนใหญ่รวมเป็นเสียงเดียว คอร์สนี้จึงสอนเสียงเดียวเป็นเป้าหมายการพูด ส่วนความหลากหลายจะสอนเป็นการฟังในระดับสูงขึ้น',
 true,'pre_a1',1),

('tap_r','ɾ',
 '[{"context":"ระหว่างสระ เช่น pero","ipa":"ɾ"},{"context":"ท้ายคำ เช่น comer","ipa":"ɾ"}]'::jsonb,
 'ตัว r หนึ่งตัวที่อยู่ระหว่างสระ และ -r ท้ายคำ',
 'ปลายลิ้นแตะปุ่มเหงือกหลังฟันบนเบา ๆ เพียงครั้งเดียวแล้วปล่อยทันที',
 'ใกล้เคียงเสียง ร ที่คนไทยพูดเร็ว ๆ แต่สั้นกว่าและไม่รัว',
 'มักออกเป็น ล หรือรัวยาวเกินไปจนกลายเป็น rr',
 '[{"a":"pero","b":"perro","note_th":"pero = แต่ / perro = สุนัข"},{"a":"caro","b":"carro"}]'::jsonb,
 null,true,'pre_a1',2),

('coda_s','s','[{"context":"ท้ายพยางค์ เช่น hablas","ipa":"s"}]'::jsonb,
 'ตัว s ท้ายคำและท้ายพยางค์',
 'ปล่อยลมผ่านร่องลิ้นที่ปุ่มเหงือก ต้องได้ยินชัดจนจบคำ',
 'ภาษาไทยไม่มีเสียง ส เป็นตัวสะกด จึงมักถูกกลืนหายไป',
 'พูด hablas เป็น habla ซึ่งเปลี่ยนความหมายจาก “คุณพูด” เป็น “เขาพูด”',
 '[{"a":"habla","b":"hablas"},{"a":"come","b":"comes"}]'::jsonb,
 'ในภาคใต้ของสเปนและหมู่เกาะคานารี เสียง -s ท้ายมักออกเป็นเสียงลมหรือหายไป ผู้เรียนจะได้ฝึกฟังในระดับสูงขึ้น',
 true,'pre_a1',3),

('trill_rr','r','[{"context":"rr และ r- ต้นคำ","ipa":"r"}]'::jsonb,
 'rr และ r ที่อยู่ต้นคำ',
 'วางปลายลิ้นหลวม ๆ ที่ปุ่มเหงือก แล้วดันลมออกให้ลิ้นสั่นเอง ใช้แรงลม ไม่ใช่แรงลิ้น',
 'ภาษาไทยมาตรฐานไม่มีเสียงสั่นรัวแบบนี้ในระบบเสียงปกติ',
 'ออกเป็น r เดี่ยว ทำให้ perro ฟังเป็น pero',
 '[{"a":"pero","b":"perro"},{"a":"caro","b":"carro"},{"a":"coro","b":"corro"}]'::jsonb,
 null,true,'a1',4),

('theta','θ','[{"context":"z ทุกตำแหน่ง และ c หน้า e/i","ipa":"θ"}]'::jsonb,
 'z ทุกตำแหน่ง และ c ที่อยู่หน้า e หรือ i',
 'สอดปลายลิ้นแตะเบา ๆ ระหว่างฟันบนกับฟันล่าง แล้วปล่อยลมผ่าน ไม่ใช้เสียงจากลำคอ',
 'ภาษาไทยไม่มีเสียงนี้ ใกล้เคียงเสียง th ในคำภาษาอังกฤษ think',
 'ออกเป็น ส ทำให้ caza ฟังเหมือน casa',
 '[{"a":"casa","b":"caza","note_th":"casa = บ้าน / caza = การล่าสัตว์"},{"a":"coser","b":"cocer"}]'::jsonb,
 'ในภาคใต้ของสเปนและในละตินอเมริกาไม่แยกเสียงนี้ (seseo) แต่คอร์สนี้สอนแบบแยกเสียงตามมาตรฐานที่ใช้ในสเปนส่วนใหญ่',
 true,'a1',5);

-- --------------------------------------------------- exercise templates ----
insert into content.exercise_templates (id, schema, skill, evidence_kind, productive, renderer) values
('mcq',            '{"type":"object","required":["stem","options"]}','grammar','recognition',false,'mcq'),
('typed',          '{"type":"object","required":["stem"]}','grammar','production',true,'typed'),
('fill_blank',     '{"type":"object","required":["template"]}','grammar','production',true,'fill_blank'),
('gender_select',  '{"type":"object","required":["noun"]}','grammar','production',true,'binary_choice'),
('conjugate',      '{"type":"object","required":["verb","person"]}','grammar','production',true,'typed'),
('listen_choose',  '{"type":"object","required":["audio_id","options"]}','listening','recognition',false,'mcq'),
('listen_type',    '{"type":"object","required":["audio_id"]}','listening','production',true,'typed'),
('minimal_pair',   '{"type":"object","required":["audio_id","options"]}','pronunciation','recognition',false,'mcq'),
('repeat_speech',  '{"type":"object","required":["scored_frame"]}','pronunciation','production',true,'record'),
('read_aloud',     '{"type":"object","required":["scored_frame"]}','speaking','production',true,'record'),
('order_words',    '{"type":"object","required":["tokens"]}','grammar','production',true,'ordering'),
('error_correct',  '{"type":"object","required":["wrong"]}','grammar','production',true,'typed');

-- -------------------------------------------------------- grammar concepts --
insert into content.grammar_concepts
 (id, slug, cefr_introduced, cefr_mastered, name_th, name_es,
  explain_l1_th, explain_l2_th, explain_l3_th, spain_usage_note, visual_model, status)
values
('11111111-1111-4111-8111-111111111101','pronoun_drop','pre_a1','a1',
 'ทำไมไม่ต้องพูดคำว่า “ฉัน”','La omisión del sujeto',
 'ในภาษาสเปน รูปของคำกริยาบอกอยู่แล้วว่าใครเป็นผู้กระทำ จึงมักไม่ต้องพูดคำว่า yo (ฉัน)',
 'คำกริยาสเปนเปลี่ยนรูปตามบุคคล เช่น hablo / hablas / habla ท้ายคำที่ต่างกันคือส่วนที่บอกว่าใครพูด เมื่อข้อมูลนี้อยู่ในคำกริยาแล้ว การเติม yo เข้าไปอีกมักใช้เพื่อเน้นเป็นพิเศษ เช่น Yo me llamo Ploy สื่อประมาณว่า “ส่วนฉันน่ะชื่อพลอย”',
 'ข้อควรระวัง: ไม่ใช่ทุกกาลที่แยกบุคคลได้ครบ ในกาลอดีต imperfecto รูปของ “ฉัน” กับ “เขา” เหมือนกัน (yo hablaba / él hablaba) กรณีแบบนี้เจ้าของภาษาจะใส่สรรพนามหรืออาศัยบริบทเพื่อไม่ให้กำกวม ภาษาไทยเองก็ละประธานได้เช่นกัน (“ไปไหนมา”) แต่ละด้วยเหตุผลต่างกัน คือละเพราะบริบท ไม่ใช่เพราะคำกริยาเปลี่ยนรูป',
 'ในสเปน การใส่ yo ทั้งที่ไม่ได้ต้องการเน้น จะฟังดูสะดุดหูเล็กน้อย',
 'morphology','published'),

('11111111-1111-4111-8111-111111111102','noun_gender','pre_a1','a1',
 'คำนามมีเพศทางไวยากรณ์','El género de los sustantivos',
 'คำนามในภาษาสเปนแบ่งเป็นสองกลุ่ม กลุ่มนี้เป็นตัวกำหนดว่าจะใช้ el หรือ la',
 'เพศทางไวยากรณ์ไม่เกี่ยวกับเพศของสิ่งของ mesa (โต๊ะ) อยู่ในกลุ่มที่ใช้ la ไม่ใช่เพราะโต๊ะเป็นผู้หญิง เทียบได้กับลักษณนามไทยที่ต้องจำว่าอะไรใช้ “ตัว” อะไรใช้ “ด้าม” โดยไม่มีเหตุผลตายตัวเสมอไป',
 'แนวโน้มที่พบบ่อย (ไม่ใช่กฎตายตัว): คำที่ลงท้าย -o มักอยู่ในกลุ่ม el ส่วนคำที่ลงท้าย -a มักอยู่ในกลุ่ม la มีคำที่ไม่เป็นไปตามแนวโน้มนี้อยู่จำนวนหนึ่ง เช่น el día, el mapa, el problema, el idioma และ la mano, la foto คำที่ลงท้าย -ción, -sión, -dad, -tad อยู่ในกลุ่ม la แทบทั้งหมด วิธีที่ได้ผลที่สุดคือจำคำนามพร้อม article เสมอ ไม่จำคำเปล่า ๆ',
 null,'agreement_arrows','published'),

('11111111-1111-4111-8111-111111111103','adjective_agreement','pre_a1','a1',
 'คำคุณศัพท์เปลี่ยนตามคำที่มันขยาย','La concordancia del adjetivo',
 'คำคุณศัพท์ในภาษาสเปนเปลี่ยนรูปให้เข้ากับคำที่มันกำลังอธิบาย',
 'คำที่ถูกอธิบายเป็นตัวกำหนด คำคุณศัพท์เป็นตัวตาม ใน la casa bonita คำว่า casa อยู่ในกลุ่ม la และเป็นเอกพจน์ bonita จึงตามรูปนั้น ไม่ได้เปลี่ยนตามเพศของคนพูด',
 'จุดที่มักสับสน: Estoy cansada ลงท้าย -a เพราะ cansada กำลังอธิบายตัวผู้พูด ถ้าผู้พูดเป็นผู้ชายจะเป็น Estoy cansado แต่ La casa está limpia ใช้ -a เพราะตามคำว่า casa ผู้ชายก็พูดประโยคนี้แบบเดียวกัน ดังนั้นให้ถามก่อนเสมอว่าคำคุณศัพท์กำลังอธิบาย “อะไร” ข้อสังเกตเพิ่มเติม: คำคุณศัพท์บางกลุ่มไม่เปลี่ยนรูปตามเพศ เช่น verde, grande, feliz จะเปลี่ยนเฉพาะพหูพจน์เท่านั้น',
 null,'agreement_arrows','published');

insert into content.grammar_concept_edges (prerequisite_id, concept_id) values
 ('11111111-1111-4111-8111-111111111102','11111111-1111-4111-8111-111111111103');

insert into content.thai_contrast_notes (concept_id, thai_reality_th, strategy_th, bridge_example) values
('11111111-1111-4111-8111-111111111102',
 'ภาษาไทยไม่มีระบบเพศทางไวยากรณ์ของคำนาม',
 'ใช้ลักษณนามไทยเป็นสะพาน คนไทยคุ้นเคยอยู่แล้วกับการที่คำนามถูกจัดกลุ่มโดยไม่มีเหตุผลตายตัวเสมอไป ระบบเพศในภาษาสเปนคือแนวคิดเดียวกัน แต่มีเพียงสองกลุ่ม',
 'ปากกา 1 ด้าม / รถ 1 คัน  ↔  el coche / la mesa'),
('11111111-1111-4111-8111-111111111101',
 'ภาษาไทยละประธานได้เป็นเรื่องปกติอยู่แล้ว',
 'บอกผู้เรียนว่าการละประธานไม่ใช่เรื่องใหม่สำหรับเขา สิ่งที่ใหม่คือการที่คำกริยาเปลี่ยนรูป',
 'ไปไหนมา ↔ ¿Adónde has ido?');

-- --------------------------------------------------------------- curriculum --
insert into content.curriculum_nodes (id, parent_id, kind, level, slug, title_th, title_es, subtitle_th, sort_order, status) values
('22222222-2222-4222-8222-222222222201', null, 'course','pre_a1','pre-a1-course','เริ่มต้นภาษาสเปน','Español desde cero','คอร์สสำหรับคนที่ไม่เคยเรียนมาก่อน',1,'published'),
('22222222-2222-4222-8222-222222222202','22222222-2222-4222-8222-222222222201','module','pre_a1','pre-a1-m1','ก้าวแรก','Primeros pasos',null,1,'published'),
('22222222-2222-4222-8222-222222222203','22222222-2222-4222-8222-222222222202','unit','pre_a1','pre-a1-u1','ทักทายและแนะนำตัว','Saludos y presentaciones','เรียนจบหน่วยนี้ คุณจะทักทายและบอกชื่อตัวเองได้',1,'published');

-- O4 no longer mentions r: "Me llamo" contains no r. The tap is introduced in
-- Unit 2 on words that actually contain one (pero, mira, gracias).
insert into content.learning_objectives (id, code, level, skill, can_do_th, can_do_es, is_core) values
('33333333-3333-4333-8333-333333333301','PRE_A1.U1.O1','pre_a1','speaking','ทักทายคนสเปนได้อย่างเป็นธรรมชาติ','Saludar',true),
('33333333-3333-4333-8333-333333333302','PRE_A1.U1.O2','pre_a1','speaking','บอกชื่อตัวเองเป็นภาษาสเปนได้','Decir cómo me llamo',true),
('33333333-3333-4333-8333-333333333303','PRE_A1.U1.O3','pre_a1','interaction','เลือกวิธีถามชื่อได้เหมาะกับคู่สนทนา (คนเดียว/หลายคน, สนิท/สุภาพ)','Preguntar el nombre',true),
('33333333-3333-4333-8333-333333333304','PRE_A1.U1.O4','pre_a1','pronunciation','ออกเสียง ll ในคำว่า llamo เป็นเสียงเพดาน (คล้าย ย) ไม่ใช่เสียง ล','Pronunciar ll',true);

-- ----------------------------------------------- Lesson 3: "Me llamo…" -----
insert into content.lessons (id, unit_id, slug, sort_order, estimated_minutes, current_version, status) values
('44444444-4444-4444-8444-444444444403','22222222-2222-4222-8222-222222222203','pre-a1-u1-l3',3,7,1,'published');

-- Completion contract for THIS lesson: both written exercises correct, and the
-- speaking task actually attempted and evaluated. Authored per lesson, verified
-- server-side by learning.complete_lesson().
insert into content.lesson_versions (id, lesson_id, version, title_th, title_es, goal_th,
  completion_rules, style_guide_version, published_at) values
('55555555-5555-4555-8555-555555555503','44444444-4444-4444-8444-444444444403',1,
 'บอกชื่อตัวเอง','Me llamo…',
 'เรียนจบบทนี้ คุณจะบอกชื่อตัวเองและถามชื่อคนอื่นเป็นภาษาสเปนได้',
 '{"required_correct_exercises":["66666666-6666-4666-8666-666666666601","66666666-6666-4666-8666-666666666602"],"required_speech_exercises":["66666666-6666-4666-8666-666666666603"],"min_blocks_viewed":9}'::jsonb,
 'sg-0.2', now());

insert into content.lesson_objectives (lesson_version_id, objective_id) values
('55555555-5555-4555-8555-555555555503','33333333-3333-4333-8333-333333333302'),
('55555555-5555-4555-8555-555555555503','33333333-3333-4333-8333-333333333303'),
('55555555-5555-4555-8555-555555555503','33333333-3333-4333-8333-333333333304');

insert into content.content_blocks
 (lesson_version_id, sort_order, block_type, payload, concept_id, why_l1_th, register) values

-- Layer 1 is the natural use, not a morphological claim.
('55555555-5555-4555-8555-555555555503',1,'example',
 '{"es":"Me llamo Ana.","th":"ฉันชื่ออานา","natural_note_th":"นี่คือวิธีปกติที่คนสเปนใช้บอกชื่อตัวเอง","audio":{"normal":"pre-a1/u1/me-llamo-ana-f-normal.m4a","slow":"pre-a1/u1/me-llamo-ana-f-slow.m4a"},"tokens":[{"t":"Me","role":"pronombre"},{"t":"llamo","role":"verbo"},{"t":"Ana","role":"nombre"}]}'::jsonb,
 '11111111-1111-4111-8111-111111111101',
 'Me llamo Ana คือวิธีปกติในการบอกชื่อตัวเองในภาษาสเปน คำว่า me เชื่อมการกระทำกลับมาที่ตัวผู้พูด และ llamo คือรูปของคำกริยาที่ใช้เมื่อผู้พูดพูดถึงตัวเอง จึงไม่ต้องเติมคำว่า yo (ฉัน) อีก',
 'neutral'),

-- Objective, target slug, focus, audio and error code all name ll.
('55555555-5555-4555-8555-555555555503',2,'pronunciation_guide',
 '{"target_slug":"ll_y_yeismo","focus":"ll","ipa_phonemic":"ʝ","ipa_phonetic":"ʝ","note_th":"ll ในคำว่า llamo ออกเป็นเสียงเพดานคล้าย ย ไม่ใช่ ล — me llamo อ่านประมาณ เม-ยา-โม","contrast_pair":{"a":"lamo","b":"llamo","note_th":"ถ้าออกเป็น ล จะกลายเป็นคำว่า lamo ซึ่งแปลว่า เลีย"},"audio":{"normal":"pre-a1/u1/llamo-word.m4a","slow":"pre-a1/u1/llamo-word-slow.m4a"}}'::jsonb,
 null,
 'ตัวอักษร ll ในภาษาสเปนไม่ได้ออกเสียงเป็น ล สองตัว แต่เป็นเสียงเดียวที่เกิดจากการยกกลางลิ้นแตะเพดาน ฟังคล้ายเสียง ย ในภาษาไทย',
 'neutral'),

('55555555-5555-4555-8555-555555555503',3,'vocabulary',
 '{"lemma":"llamarse","pos":"verbo","ipa_phonemic":"/ʝaˈmaɾse/","ipa_phonetic":"[ʝaˈmaɾ.se]","meaning_th":"ชื่อว่า","forms":[{"person":"yo","es":"me llamo"},{"person":"tú","es":"te llamas"},{"person":"él/ella","es":"se llama"},{"person":"nosotros","es":"nos llamamos"},{"person":"vosotros","es":"os llamáis"},{"person":"ellos","es":"se llaman"}],"example":{"es":"Me llamo Ana y soy de Tailandia.","th":"ฉันชื่ออานา ฉันมาจากประเทศไทย"},"audio":"pre-a1/u1/llamarse.m4a"}'::jsonb,
 null,
 'ตารางนี้แสดงทั้ง 6 รูป รวม vosotros (os llamáis) ซึ่งเป็นรูปที่คนสเปนใช้จริงเวลาคุยกับเพื่อนหลายคน',
 'neutral'),

('55555555-5555-4555-8555-555555555503',4,'exercise_embed',
 '{"exercise_slug":"pre-a1-u1-l3-e1"}'::jsonb, null, null, 'neutral'),

('55555555-5555-4555-8555-555555555503',5,'comparison',
 '{"title_th":"ถามชื่อ: เลือกให้ตรงกับคู่สนทนา","rows":[{"label_th":"คนเดียว ไม่เป็นทางการ (เพื่อน คนวัยเดียวกัน)","es":"¿Cómo te llamas?","register":"informal"},{"label_th":"คนเดียว สุภาพ (คนแปลกหน้า ผู้ใหญ่ ในที่ทำงานราชการ)","es":"¿Cómo se llama?","register":"formal"},{"label_th":"หลายคน ไม่เป็นทางการ (แบบที่ใช้ในสเปน)","es":"¿Cómo os llamáis?","register":"informal"},{"label_th":"หลายคน สุภาพ","es":"¿Cómo se llaman?","register":"formal"}],"note_th":"เวลาคุยกับเพื่อนหลายคน คนในสเปนใช้รูป vosotros (os llamáis) ส่วน ustedes ใช้เมื่อต้องการความสุภาพ ทั้งสองรูปถูกต้องในสเปน แต่ใช้คนละสถานการณ์ ในละตินอเมริกาส่วนใหญ่ใช้ ustedes กับทุกกรณี"}'::jsonb,
 null,
 'ในสเปนมีรูปสำหรับ “พวกเธอ” แยกจาก “พวกท่าน” เวลาคุยกับเพื่อนหลายคนจึงใช้ os llamáis ถ้าใช้ ustedes กับเพื่อนจะฟังดูเป็นทางการเกินสถานการณ์',
 'neutral'),

('55555555-5555-4555-8555-555555555503',6,'exercise_embed',
 '{"exercise_slug":"pre-a1-u1-l3-e2"}'::jsonb, null, null, 'neutral'),

('55555555-5555-4555-8555-555555555503',7,'dialogue',
 '{"title_th":"ในร้านกาแฟที่มาดริด","turns":[{"speaker":"A","es":"¡Hola! ¿Cómo te llamas?","th":"สวัสดี! เธอชื่ออะไร"},{"speaker":"B","es":"Me llamo Ana. ¿Y tú?","th":"ฉันชื่ออานา แล้วเธอล่ะ"},{"speaker":"A","es":"Yo soy Marta. ¡Encantada!","th":"ฉันมาร์ตา ยินดีที่ได้รู้จัก"}],"note_th":"Encantada ลงท้าย -a เพราะคำนี้กำลังอธิบายตัวมาร์ตาเอง ถ้าผู้ชายพูดจะเป็น Encantado"}'::jsonb,
 '11111111-1111-4111-8111-111111111103',
 'Encantada เปลี่ยนรูปตามเพศของผู้พูด เพราะคำนี้อธิบายตัวผู้พูดเอง ไม่ได้อธิบายคำนามอื่นในประโยค',
 'informal'),

('55555555-5555-4555-8555-555555555503',8,'speaking_prompt',
 '{"exercise_slug":"pre-a1-u1-l3-e3","display_es":"Me llamo ___","instruction_th":"กดปุ่มไมค์แล้วพูดว่า Me llamo ตามด้วยชื่อของคุณ","scored_frame":"me llamo","name_slot":true,"pron_target_slug":"ll_y_yeismo"}'::jsonb,
 null,
 'ระบบจะตรวจเฉพาะส่วน “Me llamo” เท่านั้น ชื่อของคุณไม่ถูกนำมาให้คะแนนการออกเสียง',
 'neutral'),

('55555555-5555-4555-8555-555555555503',9,'review',
 '{"title_th":"สรุปบทเรียนนี้","can_do_th":["บอกชื่อตัวเองด้วย Me llamo…","เลือกวิธีถามชื่อให้เหมาะกับคู่สนทนา","ออกเสียง ll เป็นเสียงคล้าย ย"],"watch_out_th":["ll ไม่ใช่เสียง ล — llamo ไม่ใช่ lamo","เพื่อนหลายคนใช้ os llamáis ไม่ใช่ ustedes"],"next_hint_th":"บทต่อไปจะเรียนบอกว่าคุณมาจากไหน"}'::jsonb,
 null, null, 'neutral');

-- --------------------------------------------------------------- exercises --
insert into content.exercises
 (id, template_id, objective_id, concept_id, lesson_version_id, cefr, prompt_th, payload, answer_rules, feedback, status) values

-- e1: grades the GRAMMATICAL FRAME, so any real name is accepted. v1 told the
-- learner to use their own name and then only accepted "Ploy".
-- Pattern: "me llamo" + at least one more word. accent_insensitive folds
-- á→a etc. before matching, so Thai learners are not punished for a missing
-- accent on a name.
('66666666-6666-4666-8666-666666666601','typed','33333333-3333-4333-8333-333333333302',
 '11111111-1111-4111-8111-111111111101','55555555-5555-4555-8555-555555555503','pre_a1',
 'พิมพ์เป็นภาษาสเปนว่า “ฉันชื่อ…” แล้วเติมชื่อของคุณเอง',
 '{"slug":"pre-a1-u1-l3-e1","stem":"____ + ชื่อของคุณ","hint_th":"สองคำ แล้วตามด้วยชื่อ","name_slot":true}'::jsonb,
 '{"pattern":"^me llamo[ ]+[[:alpha:]].*$","accent_insensitive":true,"model_answer":"Me llamo Ana.","error_codes":["GRAM.PERSON"]}'::jsonb,
 '{"what_changed":"me llamo","why_th":"me เชื่อมการกระทำกลับมาที่ตัวผู้พูด ส่วน llamo คือรูปที่ใช้เมื่อพูดถึงตัวเอง จึงไม่ต้องเติม yo","contrast":{"es":"Se llama Marta.","th":"เธอชื่อมาร์ตา"}}'::jsonb,
 'published'),

('66666666-6666-4666-8666-666666666602','mcq','33333333-3333-4333-8333-333333333303',
 null,'55555555-5555-4555-8555-555555555503','pre_a1',
 'คุณอยู่กับเพื่อนสองคนที่มาดริด จะถามชื่อพวกเขาว่าอย่างไร',
 '{"slug":"pre-a1-u1-l3-e2","stem":"Estás con dos amigos en Madrid.","options":["¿Cómo os llamáis?","¿Cómo se llaman ustedes?","¿Cómo te llamas?","¿Cómo se llama?"]}'::jsonb,
 '{"accepted":["¿Cómo os llamáis?"],"accent_insensitive":true,"error_codes":["GRAM.ADDRESS"]}'::jsonb,
 '{"what_changed":"os llamáis","why_th":"เพื่อนหลายคนและไม่เป็นทางการ ใช้รูป vosotros ส่วน ustedes ถูกต้องเช่นกันแต่ใช้เมื่อต้องการความสุภาพ","contrast":{"es":"¿Cómo se llaman ustedes?","th":"ใช้กับลูกค้าหรือผู้ใหญ่หลายคน"}}'::jsonb,
 'published'),

-- e3: scored_frame is what the recogniser grades. The learner's own name goes
-- in name_slot and is NEVER scored — a Thai or international proper noun must
-- not produce a phonetic error. Error code matches the taught skill (ll), not
-- coda -s as in v1.
('66666666-6666-4666-8666-666666666603','repeat_speech','33333333-3333-4333-8333-333333333304',
 null,'55555555-5555-4555-8555-555555555503','pre_a1',
 'กดปุ่มไมค์แล้วพูดว่า “Me llamo” ตามด้วยชื่อของคุณ',
 '{"slug":"pre-a1-u1-l3-e3","scored_frame":"me llamo","name_slot":true,"display_es":"Me llamo ___","pron_target_slug":"ll_y_yeismo","focus_th":"ออกเสียง ll เป็นเสียงคล้าย ย ไม่ใช่ ล","score_scope":"frame_only"}'::jsonb,
 '{"frame_pattern":"^me llamo\\b","min_confidence":0.55,"ignore_after_frame":true,"error_codes":["PRON.LL_Y"]}'::jsonb,
 '{"what_changed":"","why_th":"ถ้าเสียง ll ออกเป็น ล คำจะกลายเป็น lamo ซึ่งเป็นคนละคำ","contrast":{"es":"lamo / llamo","th":"เลีย / ฉันเรียก"}}'::jsonb,
 'published');

-- ------------------------------------------------------------- vocabulary --
-- IPA corrected to the yeísta model: /ʝ/, not /ʎ/. Phonemic and phonetic are
-- separate columns because they are different claims.
insert into content.vocabulary_entries (id, lemma, pos, gender, plural_form, ipa_phonemic, ipa_phonetic, freq_band, status) values
('77777777-7777-4777-8777-777777777701','llamarse','verbo',null,null,'/ʝaˈmaɾse/','[ʝaˈmaɾ.se]',1,'published'),
('77777777-7777-4777-8777-777777777702','nombre','sustantivo','m','nombres','/ˈnombɾe/','[ˈnõm.bɾe]',1,'published'),
('77777777-7777-4777-8777-777777777703','encantado','adjetivo','m','encantados','/enkanˈtado/','[eŋ.kãnˈta.ðo]',2,'published');

insert into content.vocabulary_senses (id, entry_id, meaning_es, meaning_th, cefr, register, spain_note) values
('88888888-8888-4888-8888-888888888801','77777777-7777-4777-8777-777777777701','tener por nombre','ชื่อว่า','pre_a1','neutral',null),
('88888888-8888-4888-8888-888888888802','77777777-7777-4777-8777-777777777702','palabra con la que se designa a alguien','ชื่อ','pre_a1','neutral',null),
('88888888-8888-4888-8888-888888888803','77777777-7777-4777-8777-777777777703','fórmula al conocer a alguien','ยินดีที่ได้รู้จัก','pre_a1','neutral',
 'ผู้ชายพูดว่า Encantado ผู้หญิงพูดว่า Encantada เพราะคำนี้อธิบายตัวผู้พูดเอง');

insert into content.vocabulary_examples (sense_id, sentence_es, meaning_th) values
('88888888-8888-4888-8888-888888888801','Me llamo Ana y soy de Tailandia.','ฉันชื่ออานา ฉันมาจากประเทศไทย'),
('88888888-8888-4888-8888-888888888802','¿Cuál es tu nombre completo?','ชื่อเต็มของคุณคืออะไร'),
('88888888-8888-4888-8888-888888888803','—Soy Marta. —¡Encantado!','“ฉันมาร์ตา” “ยินดีที่ได้รู้จักครับ”');

insert into content.collocations (sense_id, phrase, meaning_th, cefr, register) values
('88888888-8888-4888-8888-888888888802','¿Cómo te llamas?','เธอชื่ออะไร (คนเดียว ไม่เป็นทางการ)','pre_a1','informal'),
('88888888-8888-4888-8888-888888888802','¿Cómo os llamáis?','พวกเธอชื่ออะไร (หลายคน ไม่เป็นทางการ แบบที่ใช้ในสเปน)','pre_a1','informal'),
('88888888-8888-4888-8888-888888888802','¿Cómo se llama?','คุณชื่ออะไร (คนเดียว สุภาพ)','pre_a1','formal');

-- --------------------------------------------------- DELE provider (spec) ---
-- exam_specs stays empty on purpose: rows are written only by the verification
-- job against examenes.cervantes.es, never from memory.
insert into content.exam_providers (name) values ('Instituto Cervantes');
