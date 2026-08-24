/// The compiled content pack for Pre-A1 Unit 1.
///
/// This is the *read model*: published curriculum is compiled from Postgres
/// into an immutable versioned pack and served from CDN, which is what makes
/// offline work by construction. Here it is embedded as a constant so the slice
/// runs with no backend at all; swapping to a downloaded pack changes only
/// where the map comes from (`PackCurriculumRepository({pack: ...})`).
///
/// It deliberately mirrors `20260824090400_seed_reference_and_pre_a1.sql`
/// field-for-field. The lesson is NOT hardcoded into any screen: the renderer
/// reads these blocks generically, so authoring a second lesson requires no
/// Dart change.
///
/// Shape:
///   levels    : List   — CEFR levels, with `is_available` gating entry
///   units     : List   — each with an inline `lessons` summary list
///   lessons   : Map by lesson id — full detail incl. blocks
///   concepts  : Map by concept id — authored depths l1/l2/l3 (never l4)
///   exercises : Map by exercise id — payload + answer_rules + feedback
///   senses    : Map by sense id
library;

const String kPackVersion = 'pre-a1-u1.v1';
const String kStyleGuideVersion = 'sg-0.2';

/// Pre-A1 Unit 1 lesson 3. Ids match the SQL seed exactly so the same pack
/// works against the real database.
const String kLessonMeLlamoId = '44444444-4444-4444-8444-444444444403';
const String kUnitPreA1U1Id = '22222222-2222-4222-8222-222222222203';

const Map<String, dynamic> kContentPack = {
  'pack_version': kPackVersion,
  'style_guide_version': kStyleGuideVersion,
  'locale': 'es-ES',

  // ------------------------------------------------------------------ levels --
  // Levels with no QA-complete curriculum are visible but not enterable.
  // Never label incomplete content complete.
  'levels': [
    {
      'level': 'pre_a1',
      'name_th': 'เริ่มต้นจากศูนย์',
      'tagline_th': 'เสียงและคำแรกของคุณ',
      'is_available': true,
    },
    {
      'level': 'a1',
      'name_th': 'A1',
      'tagline_th': 'ชีวิตประจำวันเริ่มต้น',
      'is_available': false,
    },
    {
      'level': 'a2',
      'name_th': 'A2',
      'tagline_th': 'จัดการชีวิตในสเปนได้',
      'is_available': false,
    },
    {
      'level': 'b1',
      'name_th': 'B1',
      'tagline_th': 'แสดงความเห็นและเล่าเรื่อง',
      'is_available': false,
    },
    {
      'level': 'b2',
      'name_th': 'B2',
      'tagline_th': 'ถกเถียงและใช้ชีวิตจริง',
      'is_available': false,
    },
    {
      'level': 'c1',
      'name_th': 'C1',
      'tagline_th': 'ความละเอียดและงานอาชีพ',
      'is_available': false,
    },
    {
      'level': 'c2',
      'name_th': 'C2',
      'tagline_th': 'ความแม่นยำระดับเจ้าของภาษา',
      'is_available': false,
    },
  ],

  // ------------------------------------------------------------------- units --
  'units': [
    {
      'id': kUnitPreA1U1Id,
      'slug': 'pre-a1-u1',
      'level': 'pre_a1',
      'title_th': 'ทักทายและแนะนำตัว',
      'title_es': 'Saludos y presentaciones',
      'subtitle_th': 'เรียนจบหน่วยนี้ คุณจะทักทายและบอกชื่อตัวเองได้',
      'lessons': [
        {
          'id': kLessonMeLlamoId,
          'slug': 'pre-a1-u1-l3',
          'title_th': 'บอกชื่อตัวเอง',
          'title_es': 'Me llamo…',
          'sort_order': 3,
          'estimated_minutes': 7,
        },
      ],
    },
  ],

  // ----------------------------------------------------------------- lessons --
  'lessons': {
    kLessonMeLlamoId: {
      'id': kLessonMeLlamoId,
      'version_id': '55555555-5555-4555-8555-555555555503',
      'slug': 'pre-a1-u1-l3',
      'title_th': 'บอกชื่อตัวเอง',
      'title_es': 'Me llamo…',
      'goal_th': 'เรียนจบบทนี้ คุณจะบอกชื่อตัวเองและถามชื่อคนอื่นเป็นภาษาสเปนได้',
      'estimated_minutes': 7,

      // Server-verified contract. `learning.complete_lesson()` refuses to grant
      // completion when this is empty, so a lesson can never be a trust button.
      'completion_rules': {
        'required_correct_exercises': [
          '66666666-6666-4666-8666-666666666601',
          '66666666-6666-4666-8666-666666666602',
        ],
        'required_speech_exercises': ['66666666-6666-4666-8666-666666666603'],
        'min_blocks_viewed': 7,
      },

      'blocks': [
        {
          'id': 'blk-l3-01',
          'sort_order': 1,
          'block_type': 'example',
          'concept_id': '11111111-1111-4111-8111-111111111101',
          // Layer 1 describes the natural use, not a morphological claim.
          // "-o" marks 1sg in this paradigm; it is NOT a standalone word
          // meaning "ฉัน", and a Pre-A1 learner must not be told that it is.
          'why_l1_th':
              'Me llamo Ana คือวิธีปกติในการบอกชื่อตัวเองในภาษาสเปน คำว่า me เชื่อมการกระทำกลับมาที่ตัวผู้พูด และ llamo คือรูปของคำกริยาที่ใช้เมื่อผู้พูดพูดถึงตัวเอง จึงไม่ต้องเติมคำว่า yo (ฉัน) อีก',
          'payload': {
            'es': 'Me llamo Ana.',
            'th': 'ฉันชื่ออานา',
            'natural_note_th': 'นี่คือวิธีปกติที่คนสเปนใช้บอกชื่อตัวเอง',
            'audio': {
              'normal': 'pre-a1/u1/me-llamo-ana-f-normal.m4a',
              'slow': 'pre-a1/u1/me-llamo-ana-f-slow.m4a',
            },
            'tokens': [
              {'t': 'Me', 'role': 'pronombre', 'th': 'ตัวฉัน'},
              {
                't': 'llamo',
                'role': 'verbo',
                'th': 'เรียก (ผู้พูดเป็นคนทำ)',
                'segments': [
                  {'s': 'llam-', 'th': 'รากของ llamar “เรียก”'},
                  {'s': '-o', 'th': 'รูปบุรุษที่ 1 เอกพจน์ในรูปนี้'},
                ],
              },
              {'t': 'Ana', 'role': 'nombre', 'th': 'ชื่อคน'},
            ],
          },
        },
        {
          'id': 'blk-l3-02',
          'sort_order': 2,
          'block_type': 'pronunciation_guide',
          'concept_id': null,
          'why_l1_th':
              'ตัวอักษร ll ในภาษาสเปนไม่ได้ออกเสียงเป็น ล สองตัว แต่เป็นเสียงเดียวที่เกิดจากการยกกลางลิ้นแตะเพดาน ฟังคล้ายเสียง ย ในภาษาไทย',
          // Course standard sg-0.2: distinción for /s/–/θ/, but YEÍSMO for
          // ⟨ll⟩/⟨y⟩ — both are /ʝ/. We do not teach /ʎ/, because most speakers
          // the learner will meet do not use it and our audio does not either.
          'payload': {
            'target_slug': 'll_y_yeismo',
            'focus': 'll',
            'ipa_phonemic': 'ʝ',
            'ipa_phonetic': 'ʝ',
            'note_th':
                'll ในคำว่า llamo ออกเป็นเสียงเพดานคล้าย ย ไม่ใช่ ล — me llamo อ่านประมาณ เม-ยา-โม',
            'contrast_pair': {
              'a': 'lamo',
              'b': 'llamo',
              'note_th': 'ถ้าออกเป็น ล จะกลายเป็นคำว่า lamo ซึ่งแปลว่า เลีย',
            },
            'audio': {
              'normal': 'pre-a1/u1/llamo-word.m4a',
              'slow': 'pre-a1/u1/llamo-word-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-l3-03',
          'sort_order': 3,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666601'},
        },
        {
          'id': 'blk-l3-04',
          'sort_order': 4,
          'block_type': 'comparison',
          'concept_id': null,
          'why_l1_th':
              'ในสเปนมีรูปสำหรับ “พวกเธอ” แยกจาก “พวกท่าน” เวลาคุยกับเพื่อนหลายคนจึงใช้ os llamáis ถ้าใช้ ustedes กับเพื่อนจะฟังดูเป็นทางการเกินสถานการณ์',
          'payload': {
            'title_th': 'ถามชื่อ: เลือกให้ตรงกับคู่สนทนา',
            'rows': [
              {
                'label_th': 'คนเดียว ไม่เป็นทางการ (เพื่อน คนวัยเดียวกัน)',
                'es': '¿Cómo te llamas?',
                'register': 'informal',
              },
              {
                'label_th': 'คนเดียว สุภาพ (คนแปลกหน้า ผู้ใหญ่ ในที่ราชการ)',
                'es': '¿Cómo se llama?',
                'register': 'formal',
              },
              {
                'label_th': 'หลายคน ไม่เป็นทางการ (แบบที่ใช้ในสเปน)',
                'es': '¿Cómo os llamáis?',
                'register': 'informal',
              },
              {
                'label_th': 'หลายคน สุภาพ',
                'es': '¿Cómo se llaman?',
                'register': 'formal',
              },
            ],
            'note_th':
                'เวลาคุยกับเพื่อนหลายคน คนในสเปนใช้รูป vosotros (os llamáis) ส่วน ustedes ใช้เมื่อต้องการความสุภาพ ทั้งสองรูปถูกต้องในสเปน แต่ใช้คนละสถานการณ์ ในละตินอเมริกาส่วนใหญ่ใช้ ustedes กับทุกกรณี',
          },
        },
        {
          'id': 'blk-l3-05',
          'sort_order': 5,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666602'},
        },
        {
          'id': 'blk-l3-06',
          'sort_order': 6,
          'block_type': 'dialogue',
          'concept_id': '11111111-1111-4111-8111-111111111103',
          'why_l1_th':
              'Encantada เปลี่ยนรูปตามเพศของผู้พูด เพราะคำนี้อธิบายตัวผู้พูดเอง ไม่ได้อธิบายคำนามอื่นในประโยค',
          'payload': {
            'title_th': 'ในร้านกาแฟที่มาดริด',
            'turns': [
              {
                'speaker': 'A',
                'es': '¡Hola! ¿Cómo te llamas?',
                'th': 'สวัสดี! เธอชื่ออะไร',
              },
              {
                'speaker': 'B',
                'es': 'Me llamo Ana. ¿Y tú?',
                'th': 'ฉันชื่ออานา แล้วเธอล่ะ',
              },
              {
                'speaker': 'A',
                'es': 'Yo soy Marta. ¡Encantada!',
                'th': 'ฉันมาร์ตา ยินดีที่ได้รู้จัก',
              },
            ],
            'note_th':
                'Encantada ลงท้าย -a เพราะคำนี้กำลังอธิบายตัวมาร์ตาเอง ถ้าผู้ชายพูดจะเป็น Encantado',
          },
        },
        {
          'id': 'blk-l3-07',
          'sort_order': 7,
          'block_type': 'vocabulary',
          'concept_id': null,
          'payload': {
            'sense_ids': [
              '88888888-8888-4888-8888-888888888801',
              '88888888-8888-4888-8888-888888888803',
            ],
          },
        },
        {
          'id': 'blk-l3-08',
          'sort_order': 8,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666603'},
        },
        {
          'id': 'blk-l3-09',
          'sort_order': 9,
          'block_type': 'review',
          'concept_id': null,
          'payload': {
            'title_th': 'สรุปบทนี้',
            'points_th': [
              'Me llamo + ชื่อ = การบอกชื่อตัวเองแบบปกติ',
              'll ออกเป็นเสียงคล้าย ย ไม่ใช่ ล',
              'เพื่อนหลายคนในสเปน ใช้ ¿Cómo os llamáis?',
            ],
            // Progress framed as ability, never as points.
            'th': 'ตอนนี้คุณบอกชื่อตัวเองและถามชื่อคนอื่นเป็นภาษาสเปนได้แล้ว',
          },
        },
      ],
    },
  },

  // ---------------------------------------------------------------- concepts --
  // Authored depths only. l4 is deliberately absent: it is the one tier that
  // may be generated at request time, and it must be labelled as generated.
  'concepts': {
    '11111111-1111-4111-8111-111111111101': {
      'id': '11111111-1111-4111-8111-111111111101',
      'slug': 'pronoun_drop',
      'name_th': 'ทำไมไม่ต้องพูดคำว่า “ฉัน”',
      'name_es': 'La omisión del sujeto',
      'l1':
          'ในภาษาสเปน รูปของคำกริยาบอกอยู่แล้วว่าใครเป็นผู้กระทำ จึงมักไม่ต้องพูดคำว่า yo (ฉัน)',
      'l2':
          'คำกริยาสเปนเปลี่ยนรูปตามบุคคล เช่น hablo / hablas / habla ท้ายคำที่ต่างกันคือส่วนที่บอกว่าใครพูด เมื่อข้อมูลนี้อยู่ในคำกริยาแล้ว การเติม yo เข้าไปอีกมักใช้เพื่อเน้นเป็นพิเศษ เช่น Yo me llamo Ana สื่อประมาณว่า “ส่วนฉันน่ะชื่ออานา”',
      'l3':
          'ข้อควรระวัง: ไม่ใช่ทุกกาลที่แยกบุคคลได้ครบ ในกาลอดีต imperfecto รูปของ “ฉัน” กับ “เขา” เหมือนกัน (yo hablaba / él hablaba) กรณีแบบนี้เจ้าของภาษาจะใส่สรรพนามหรืออาศัยบริบทเพื่อไม่ให้กำกวม',
      'spain_note':
          'ในสเปน การใส่ yo ทั้งที่ไม่ได้ต้องการเน้น จะฟังดูสะดุดหูเล็กน้อย',
      'thai_contrast':
          'ภาษาไทยละประธานได้เป็นเรื่องปกติอยู่แล้ว (“ไปไหนมา”) การละประธานจึงไม่ใช่เรื่องใหม่สำหรับผู้เรียนไทย สิ่งที่ใหม่คือการที่คำกริยาเปลี่ยนรูปตามบุคคล ภาษาไทยละเพราะบริบท ภาษาสเปนละได้เพราะรูปคำกริยาบอกอยู่แล้ว',
    },
    '11111111-1111-4111-8111-111111111103': {
      'id': '11111111-1111-4111-8111-111111111103',
      'slug': 'adjective_agreement',
      'name_th': 'คำคุณศัพท์เปลี่ยนตามคำที่มันขยาย',
      'name_es': 'La concordancia del adjetivo',
      'l1': 'คำคุณศัพท์ในภาษาสเปนเปลี่ยนรูปให้เข้ากับคำที่มันกำลังอธิบาย',
      'l2':
          'คำที่ถูกอธิบายเป็นตัวกำหนด คำคุณศัพท์เป็นตัวตาม ใน la casa bonita คำว่า casa อยู่ในกลุ่ม la และเป็นเอกพจน์ bonita จึงตามรูปนั้น ไม่ได้เปลี่ยนตามเพศของคนพูด',
      'l3':
          'จุดที่มักสับสน: Estoy cansada ลงท้าย -a เพราะ cansada กำลังอธิบายตัวผู้พูด ถ้าผู้พูดเป็นผู้ชายจะเป็น Estoy cansado แต่ La casa está limpia ใช้ -a เพราะตามคำว่า casa ผู้ชายก็พูดประโยคนี้แบบเดียวกัน ข้อสังเกตเพิ่มเติม: คำคุณศัพท์บางกลุ่มไม่เปลี่ยนรูปตามเพศ เช่น verde, grande, feliz จะเปลี่ยนเฉพาะพหูพจน์เท่านั้น',
      'spain_note': null,
      'thai_contrast':
          'ภาษาไทยไม่มีระบบเพศทางไวยากรณ์ ใช้ลักษณนามเป็นสะพานได้ คนไทยคุ้นเคยอยู่แล้วกับการที่คำนามถูกจัดกลุ่มโดยไม่มีเหตุผลตายตัวเสมอไป (ปากกา 1 ด้าม / รถ 1 คัน)',
    },
  },

  // --------------------------------------------------------------- exercises --
  'exercises': {
    // Grades the FRAME, so any real name is accepted. Telling a learner to use
    // their own name and then only accepting one name would be wrong.
    '66666666-6666-4666-8666-666666666601': {
      'id': '66666666-6666-4666-8666-666666666601',
      'template_id': 'typed',
      'objective_id': '33333333-3333-4333-8333-333333333302',
      'concept_id': '11111111-1111-4111-8111-111111111101',
      'prompt_th': 'พิมพ์เป็นภาษาสเปนว่า “ฉันชื่อ…” แล้วเติมชื่อของคุณเอง',
      'payload': {
        'stem': '____ + ชื่อของคุณ',
        'th': 'สองคำ แล้วตามด้วยชื่อ',
      },
      'answer_rules': {
        'pattern': r'^me llamo[ ]+[a-zà-ÿ].*$',
        'accent_insensitive': true,
        'model_answer': 'Me llamo Ana.',
        'error_codes': ['GRAM.PERSON'],
      },
      'feedback': {
        'what_changed': 'me llamo',
        'why_th':
            'me เชื่อมการกระทำกลับมาที่ตัวผู้พูด ส่วน llamo คือรูปที่ใช้เมื่อพูดถึงตัวเอง จึงไม่ต้องเติม yo',
        'contrast': {'es': 'Se llama Marta.', 'th': 'เธอชื่อมาร์ตา'},
      },
    },
    '66666666-6666-4666-8666-666666666602': {
      'id': '66666666-6666-4666-8666-666666666602',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333303',
      'concept_id': null,
      'prompt_th': 'คุณอยู่กับเพื่อนสองคนที่มาดริด จะถามชื่อพวกเขาว่าอย่างไร',
      'payload': {
        'stem': 'Estás con dos amigos en Madrid.',
        'options': [
          '¿Cómo os llamáis?',
          '¿Cómo se llaman ustedes?',
          '¿Cómo te llamas?',
          '¿Cómo se llama?',
        ],
      },
      'answer_rules': {
        'accepted': ['¿Cómo os llamáis?'],
        'accent_insensitive': true,
        'error_codes': ['GRAM.ADDRESS'],
      },
      'feedback': {
        'what_changed': 'os llamáis',
        'why_th':
            'เพื่อนหลายคนและไม่เป็นทางการ ใช้รูป vosotros ส่วน ustedes ถูกต้องเช่นกันแต่ใช้เมื่อต้องการความสุภาพ',
        'contrast': {
          'es': '¿Cómo se llaman ustedes?',
          'th': 'ใช้กับลูกค้าหรือผู้ใหญ่หลายคน',
        },
      },
    },
    // scored_frame is what a recogniser would grade. The learner's own name is
    // content, not a pronunciation target, and must never generate a phonetic
    // error. This build has no ASR at all — see speaking_view.dart.
    '66666666-6666-4666-8666-666666666603': {
      'id': '66666666-6666-4666-8666-666666666603',
      'template_id': 'repeat_speech',
      'objective_id': '33333333-3333-4333-8333-333333333304',
      'concept_id': null,
      'prompt_th': 'กดปุ่มไมค์แล้วพูดว่า “Me llamo” ตามด้วยชื่อของคุณ',
      'payload': {
        'es': 'Me llamo ___',
        'th': 'ออกเสียง ll เป็นเสียงคล้าย ย ไม่ใช่ ล',
        'target_slug': 'll_y_yeismo',
        'focus': 'll',
      },
      'answer_rules': {
        'frame_pattern': r'^me llamo\b',
        'min_confidence': 0.55,
        'error_codes': ['PRON.LL_Y'],
      },
      'feedback': {
        'what_changed': '',
        'why_th': 'ถ้าเสียง ll ออกเป็น ล คำจะกลายเป็น lamo ซึ่งเป็นคนละคำ',
        'contrast': {'es': 'lamo / llamo', 'th': 'เลีย / ฉันเรียก'},
      },
    },
  },

  // ------------------------------------------------------------------ senses --
  'senses': {
    '88888888-8888-4888-8888-888888888801': {
      'id': '88888888-8888-4888-8888-888888888801',
      'lemma': 'llamarse',
      'pos': 'verbo',
      'gender': null,
      'plural_form': null,
      'meaning_th': 'ชื่อว่า',
      // Yeísta model, matching the taught target and the reference audio.
      'ipa_phonemic': '/ʝaˈmaɾse/',
      'ipa_phonetic': '[ʝaˈmaɾ.se]',
      'spain_note': null,
      'examples': [
        {
          'es': 'Me llamo Ana y soy de Tailandia.',
          'th': 'ฉันชื่ออานา ฉันมาจากประเทศไทย',
        },
      ],
      'collocations': [
        {'phrase': '¿Cómo te llamas?', 'th': 'เธอชื่ออะไร (คนเดียว ไม่เป็นทางการ)'},
        {
          'phrase': '¿Cómo os llamáis?',
          'th': 'พวกเธอชื่ออะไร (หลายคน ไม่เป็นทางการ แบบที่ใช้ในสเปน)',
        },
        {'phrase': '¿Cómo se llama?', 'th': 'คุณชื่ออะไร (คนเดียว สุภาพ)'},
      ],
    },
    '88888888-8888-4888-8888-888888888803': {
      'id': '88888888-8888-4888-8888-888888888803',
      'lemma': 'encantado',
      'pos': 'adjetivo',
      'gender': 'm',
      'plural_form': 'encantados',
      'meaning_th': 'ยินดีที่ได้รู้จัก',
      'ipa_phonemic': '/enkanˈtado/',
      'ipa_phonetic': '[eŋ.kãnˈta.ðo]',
      'spain_note':
          'ผู้ชายพูดว่า Encantado ผู้หญิงพูดว่า Encantada เพราะคำนี้อธิบายตัวผู้พูดเอง',
      'examples': [
        {'es': '—Soy Marta. —¡Encantado!', 'th': '“ฉันมาร์ตา” “ยินดีที่ได้รู้จักครับ”'},
      ],
      'collocations': [],
    },
  },
};
