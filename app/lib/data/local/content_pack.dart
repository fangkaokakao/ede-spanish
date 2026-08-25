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

const String kPackVersion = 'foundation0-pre-a1-u1.v1';
const String kStyleGuideVersion = 'sg-0.2';

/// Pre-A1 Unit 1 lesson 3. Ids match the SQL seed exactly so the same pack
/// works against the real database. STABLE — never change these.
const String kLessonMeLlamoId = '44444444-4444-4444-8444-444444444403';
const String kUnitPreA1U1Id = '22222222-2222-4222-8222-222222222203';

/// Foundation 0: the first unit a learner ever sees, one course-position
/// ahead of Pre-A1 Unit 1 (sort_order 0 vs 1). New ids, a different suffix
/// family from the seeded Unit 1 / Lesson 3 fixtures above, so nothing here
/// collides with or renumbers a UUID something else already depends on.
const String kUnitFoundation0Id = '22222222-2222-4222-8222-222222222200';
const String kLessonFoundation0L1Id = '44444444-4444-4444-8444-444444444401';
const String kLessonFoundation0L1Slug = 'foundation-0-l1';

/// Foundation 0, Lesson 0: the opening sound-and-reading lesson (Spanish
/// alphabet + the five vowels), one course-position ahead of the existing
/// "Hola, ¿qué tal?" lesson (sort_order 0 vs 1 within the unit — see
/// kLessonFoundation0L1Id above, which keeps its own sort_order and id
/// untouched). New id, same suffix family as the rest of Foundation 0.
const String kLessonFoundation0L0Id = '44444444-4444-4444-8444-444444444400';
const String kLessonFoundation0L0Slug = 'foundation-0-l0';

/// Lesson slugs with a real, content-complete pack entry. A unit can legally
/// list a lesson stub that is not in here yet — QA-incomplete content is
/// shown but never made to look tappable (see CourseMapScreen/UnitScreen).
const Set<String> kAvailableLessonSlugs = {
  'pre-a1-u1-l3',
  kLessonFoundation0L0Slug,
  kLessonFoundation0L1Slug,
};

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
      'id': kUnitFoundation0Id,
      'slug': 'foundation-0',
      'level': 'pre_a1',
      'sort_order': 0,
      'title_th': 'ปูพื้นฐาน: เสียงและคำทักทายแรก',
      'title_es': 'Fundamentos: sonidos y primeros saludos',
      'subtitle_th':
          'ก่อนเริ่มบทเรียนแรก ทำความรู้จักตัวอักษร เสียงสระ คำทักทายพื้นฐาน '
          'และเสียง c/z แบบสเปน',
      'lessons': [
        {
          'id': kLessonFoundation0L0Id,
          'slug': kLessonFoundation0L0Slug,
          'title_th': 'ตัวอักษรและเสียงสระภาษาสเปน',
          'title_es': 'El alfabeto y las vocales',
          'sort_order': 0,
          'estimated_minutes': 8,
        },
        {
          'id': kLessonFoundation0L1Id,
          'slug': kLessonFoundation0L1Slug,
          'title_th': 'สวัสดีแบบสเปน',
          'title_es': 'Hola, ¿qué tal?',
          'sort_order': 1,
          'estimated_minutes': 6,
        },
      ],
    },
    {
      'id': kUnitPreA1U1Id,
      'slug': 'pre-a1-u1',
      'level': 'pre_a1',
      'sort_order': 1,
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
    kLessonFoundation0L0Id: {
      'id': kLessonFoundation0L0Id,
      'version_id': '55555555-5555-4555-8555-555555555500',
      'slug': kLessonFoundation0L0Slug,
      'title_th': 'ตัวอักษรและเสียงสระภาษาสเปน',
      'title_es': 'El alfabeto y las vocales',
      'goal_th':
          'เรียนจบบทนี้ คุณจะรู้จักตัวอักษรภาษาสเปนทั้งหมด และออกเสียงสระ 5 ตัว '
          '(a e i o u) ได้สั้น ชัด และคงที่แบบสเปน',
      'estimated_minutes': 8,

      'completion_rules': {
        'required_correct_exercises': [
          '66666666-6666-4666-8666-666666666610',
          '66666666-6666-4666-8666-666666666611',
          '66666666-6666-4666-8666-666666666612',
          '66666666-6666-4666-8666-666666666613',
        ],
        'required_speech_exercises': ['66666666-6666-4666-8666-666666666614'],
        'min_blocks_viewed': 14,
      },

      'blocks': [
        {
          'id': 'blk-l0a-01',
          'sort_order': 1,
          'block_type': 'heading',
          'concept_id': null,
          'payload': {'th': 'ก่อนเริ่มภาษาสเปนจริง: เสียงและการอ่าน'},
        },
        {
          'id': 'blk-l0a-02',
          'sort_order': 2,
          'block_type': 'explanation',
          'concept_id': '11111111-1111-4111-8111-111111111106',
          'why_l1_th':
              'ถ้าออกเสียงตัวอักษรผิดตั้งแต่ต้น จะติดนิสัยและแก้ยากในบทเรียนหลังๆ '
              'จึงปูพื้นเสียงและการอ่านให้แม่นก่อน แล้วค่อยเข้าเนื้อหาไวยากรณ์และบทสนทนาจริง',
          'payload': {
            'title_th': 'ทำไมต้องเรียนเสียงก่อน',
            'th':
                'ฉันกำลังเรียนเสียงและการอ่านก่อนเริ่มภาษาสเปนจริง — บทเรียนชุด '
                '"ปูพื้นฐาน" นี้ไม่ได้สอนไวยากรณ์หรือบทสนทนา แต่ฝึกให้หูจับเสียงสเปนได้ '
                'ปากออกเสียงได้ถูกต้อง และตาอ่านตัวอักษรสเปนออกอย่างมั่นใจ ก่อนที่จะเริ่มบทเรียนที่ใช้เสียงเหล่านี้จริงๆ',
          },
        },
        {
          'id': 'blk-l0a-03',
          'sort_order': 3,
          'block_type': 'explanation',
          'concept_id': null,
          'why_l1_th':
              'ตั้งแต่ปี 2010 ราชบัณฑิตยสถานสเปน (RAE) ไม่นับ ch และ ll เป็นตัวอักษรแยกอีกต่อไป '
              'แต่ยังคงเขียนและออกเสียงเหมือนเดิมทุกประการ จึงยังต้องรู้จักไว้',
          'payload': {
            'title_th': 'ตัวอักษรภาษาสเปน 27 ตัว',
            'th':
                'a (a) · b (be) · c (ce) · d (de) · e (e) · f (efe) · g (ge) · '
                'h (hache) · i (i) · j (jota) · k (ka) · l (ele) · m (eme) · '
                'n (ene) · ñ (eñe) · o (o) · p (pe) · q (cu) · r (erre) · '
                's (ese) · t (te) · u (u) · v (uve) · w (uve doble) · '
                'x (equis) · y (i griega / ye) · z (zeta)\n\n'
                'ตัวอักษรเดียวที่มีเฉพาะในภาษาสเปนคือ ñ (eñe) ส่วน ch และ ll เป็น '
                'digraph (สองตัวรวมเป็นหนึ่งเสียง) ที่จะได้เรียนในบทถัดไป',
          },
        },
        {
          'id': 'blk-l0a-04',
          'sort_order': 4,
          'block_type': 'pronunciation_guide',
          'concept_id': null,
          'why_l1_th':
              'สระ a ในภาษาสเปนอ้าปากกว้างและออกเสียงสั้นคงที่เสมอ ไม่ว่าจะอยู่ตำแหน่งไหนของคำ',
          'payload': {
            'target_slug': 'vowel_a',
            'focus': 'a',
            'ipa_phonemic': 'a',
            'note_th':
                'อ้าปากกว้าง ลิ้นอยู่ต่ำและกลางปาก ออกเสียงสั้นและคงที่ '
                'ไม่ลากยาวหรือเปลี่ยนเสียงกลางคำเหมือนสระในภาษาอังกฤษบางคำ',
            'thai_helper_th': 'อา',
            'example': {'es': 'casa', 'th': 'บ้าน'},
            'syllables': ['ca', 'sa'],
            'audio': {
              'normal': 'foundation-0/l0/vowel-a-normal.m4a',
              'slow': 'foundation-0/l0/vowel-a-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-l0a-05',
          'sort_order': 5,
          'block_type': 'pronunciation_guide',
          'concept_id': null,
          'why_l1_th':
              'สระ e ในภาษาสเปนออกเสียงสั้นและคงที่ ต่างจาก e ในหลายคำภาษาอังกฤษที่มักลดรูปเป็นเสียงเบา (schwa)',
          'payload': {
            'target_slug': 'vowel_e',
            'focus': 'e',
            'ipa_phonemic': 'e',
            'note_th':
                'อ้าปากแคบกว่า a เล็กน้อย มุมปากยกขึ้นทั้งสองข้าง ออกเสียงสั้นและคงที่ ไม่เพี้ยนเป็นเสียง แอ หรือ เออ',
            'thai_helper_th': 'เอ',
            'example': {'es': 'este', 'th': 'อันนี้'},
            'syllables': ['es', 'te'],
            'audio': {
              'normal': 'foundation-0/l0/vowel-e-normal.m4a',
              'slow': 'foundation-0/l0/vowel-e-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-l0a-06',
          'sort_order': 6,
          'block_type': 'pronunciation_guide',
          'concept_id': null,
          'why_l1_th': 'สระ i เป็นเสียงสั้นและแหลมที่สุดในกลุ่มสระสเปน',
          'payload': {
            'target_slug': 'vowel_i',
            'focus': 'i',
            'ipa_phonemic': 'i',
            'note_th': 'ยิ้มเล็กน้อย ลิ้นอยู่สูงและหน้า ออกเสียงสั้น ไม่ลากยาวแบบ อี ในภาษาไทยเวลาเน้นคำ',
            'thai_helper_th': 'อี',
            'example': {'es': 'sí', 'th': 'ใช่'},
            'syllables': [],
            'audio': {
              'normal': 'foundation-0/l0/vowel-i-normal.m4a',
              'slow': 'foundation-0/l0/vowel-i-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-l0a-07',
          'sort_order': 7,
          'block_type': 'pronunciation_guide',
          'concept_id': null,
          'why_l1_th': 'สระ o อยู่กึ่งกลางระหว่างปากกลมสนิทกับปากแบน และไม่เปลี่ยนเป็นเสียง โอว แบบภาษาอังกฤษ',
          'payload': {
            'target_slug': 'vowel_o',
            'focus': 'o',
            'ipa_phonemic': 'o',
            'note_th':
                'ห่อริมฝีปากเป็นวงกลมพอประมาณ ออกเสียงสั้นและคงที่ตลอดคำ ไม่เลื่อนไปเป็นเสียงสระประสม โอว เหมือนคำว่า "go" ในภาษาอังกฤษ',
            'thai_helper_th': 'โอ',
            'example': {'es': 'no', 'th': 'ไม่'},
            'syllables': [],
            'audio': {
              'normal': 'foundation-0/l0/vowel-o-normal.m4a',
              'slow': 'foundation-0/l0/vowel-o-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-l0a-08',
          'sort_order': 8,
          'block_type': 'pronunciation_guide',
          'concept_id': null,
          'why_l1_th': 'สระ u ห่อริมฝีปากแคบและกลมที่สุดในกลุ่มสระสเปน',
          'payload': {
            'target_slug': 'vowel_u',
            'focus': 'u',
            'ipa_phonemic': 'u',
            'note_th': 'ห่อริมฝีปากให้กลมและแคบ ลิ้นอยู่สูงและหลัง ออกเสียงสั้นและคงที่',
            'thai_helper_th': 'อู',
            'example': {'es': 'uno', 'th': 'หนึ่ง'},
            'syllables': ['u', 'no'],
            'audio': {
              'normal': 'foundation-0/l0/vowel-u-normal.m4a',
              'slow': 'foundation-0/l0/vowel-u-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-l0a-09',
          'sort_order': 9,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666610'},
        },
        {
          'id': 'blk-l0a-10',
          'sort_order': 10,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666611'},
        },
        {
          'id': 'blk-l0a-11',
          'sort_order': 11,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666612'},
        },
        {
          'id': 'blk-l0a-12',
          'sort_order': 12,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666613'},
        },
        {
          'id': 'blk-l0a-13',
          'sort_order': 13,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666614'},
        },
        {
          'id': 'blk-l0a-14',
          'sort_order': 14,
          'block_type': 'review',
          'concept_id': null,
          'payload': {
            'title_th': 'สรุปบทนี้',
            'points_th': [
              'ตัวอักษรภาษาสเปนมี 27 ตัว รวม ñ ที่ไม่มีในภาษาอังกฤษ',
              'สระสเปนมี 5 เสียง (a e i o u) และออกเสียงสั้น ชัด คงที่เสมอ ไม่ลดรูปหรือลากเสียง',
              'เสียงสระไทย (อา เอ อี โอ อู) ใกล้เคียงเสียงสระสเปนพอเป็นสะพานได้ แต่ไม่เหมือนกันทุกประการ',
            ],
            'th': 'ตอนนี้คุณรู้จักตัวอักษรสเปนและออกเสียงสระทั้ง 5 ตัวได้แล้ว',
          },
        },
      ],
    },
    kLessonFoundation0L1Id: {
      'id': kLessonFoundation0L1Id,
      'version_id': '55555555-5555-4555-8555-555555555501',
      'slug': kLessonFoundation0L1Slug,
      'title_th': 'สวัสดีแบบสเปน',
      'title_es': 'Hola, ¿qué tal?',
      'goal_th':
          'เรียนจบบทนี้ คุณจะทักทายเป็นภาษาสเปนได้ และรู้จักเสียง c/z แบบสเปน (distinción)',
      'estimated_minutes': 6,

      'completion_rules': {
        'required_correct_exercises': [
          '66666666-6666-4666-8666-666666666604',
          '66666666-6666-4666-8666-666666666605',
        ],
        'required_speech_exercises': ['66666666-6666-4666-8666-666666666606'],
        'min_blocks_viewed': 6,
      },

      'blocks': [
        {
          'id': 'blk-l0-01',
          'sort_order': 1,
          'block_type': 'example',
          'concept_id': null,
          'why_l1_th':
              '¡Hola! ¿Qué tal? เป็นคำทักทายที่ใช้ได้แทบทุกสถานการณ์และทุกช่วงเวลาของวัน ไม่ว่าจะเป็นทางการหรือไม่เป็นทางการ',
          'payload': {
            'es': '¡Hola! ¿Qué tal?',
            'th': 'สวัสดี เป็นอย่างไรบ้าง',
            'natural_note_th': 'เป็นคำทักทายที่คนสเปนใช้บ่อยที่สุดในชีวิตประจำวัน',
            'audio': {
              'normal': 'foundation-0/l1/hola-que-tal-normal.m4a',
              'slow': 'foundation-0/l1/hola-que-tal-slow.m4a',
            },
            'tokens': [
              {'t': 'Hola', 'role': 'interjección', 'th': 'สวัสดี'},
              {'t': 'qué', 'role': 'pronombre', 'th': 'อะไร/อย่างไร'},
              {'t': 'tal', 'role': 'adverbio', 'th': 'เป็นอย่างไร (สำนวน)'},
            ],
          },
        },
        {
          'id': 'blk-l0-02',
          'sort_order': 2,
          'block_type': 'pronunciation_guide',
          'concept_id': '11111111-1111-4111-8111-111111111105',
          'why_l1_th':
              'ในภาษาสเปนแบบสเปน (Spain Spanish) ตัวอักษร z และ c หน้าสระ e/i ออกเสียงเป็น th แบบภาษาอังกฤษ ไม่ใช่เสียง ส เหมือนในภาษาสเปนของละตินอเมริกาส่วนใหญ่ ลักษณะนี้เรียกว่า distinción',
          // Course standard sg-0.2: distinción for /s/–/θ/. This is the
          // headline phonological difference between Spain Spanish and most
          // Latin American varieties (which use seseo, merging both to /s/).
          'payload': {
            'target_slug': 'c_z_distincion',
            'focus': 'z',
            'ipa_phonemic': 'θ',
            'ipa_phonetic': 'θ',
            'note_th':
                'z และ c (หน้า e/i) ในสเปนออกเสียงโดยเอาปลายลิ้นแตะฟันบน คล้ายเสียง th ในคำภาษาอังกฤษ think ไม่ใช่เสียง ส',
            'contrast_pair': {
              'a': 'casa',
              'b': 'caza',
              'note_th':
                  'casa (บ้าน) กับ caza (การล่าสัตว์) ออกเสียงเหมือนกันในสำเนียงที่ใช้ seseo แต่ในสเปนออกเสียงต่างกันชัดเจน: casa ใช้เสียง ส ส่วน caza ใช้เสียง th',
            },
            'audio': {
              'normal': 'foundation-0/l1/casa-caza-normal.m4a',
              'slow': 'foundation-0/l1/casa-caza-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-l0-03',
          'sort_order': 3,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666604'},
        },
        {
          'id': 'blk-l0-04',
          'sort_order': 4,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666605'},
        },
        {
          'id': 'blk-l0-05',
          'sort_order': 5,
          'block_type': 'exercise_embed',
          'concept_id': null,
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666606'},
        },
        {
          'id': 'blk-l0-06',
          'sort_order': 6,
          'block_type': 'review',
          'concept_id': null,
          'payload': {
            'title_th': 'สรุปบทนี้',
            'points_th': [
              '¡Hola! ¿Qué tal? = คำทักทายที่ใช้ได้แทบทุกสถานการณ์',
              'z และ c หน้า e/i ในสเปนออกเป็นเสียง th ไม่ใช่เสียง ส',
              'casa (บ้าน) กับ caza (การล่าสัตว์) ออกเสียงต่างกันในสเปน',
            ],
            'th': 'ตอนนี้คุณทักทายเป็นภาษาสเปนได้ และแยกเสียง casa/caza แบบสเปนได้แล้ว',
          },
        },
      ],
    },
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
    '11111111-1111-4111-8111-111111111106': {
      'id': '11111111-1111-4111-8111-111111111106',
      'slug': 'vowels_pure',
      'name_th': 'ทำไมสระสเปนไม่ลากเสียงหรือเปลี่ยนเสียงกลางคำ',
      'name_es': 'La pureza vocálica',
      'l1':
          'ภาษาสเปนมีสระแค่ 5 เสียง (a e i o u) และแต่ละเสียงจะออกสั้น ชัด และคงที่เสมอ ไม่ว่าจะอยู่ตำแหน่งไหนของคำ',
      'l2':
          'ต่างจากภาษาอังกฤษที่สระในพยางค์ที่ไม่เน้นเสียงมักลดรูปเป็นเสียงเบา (schwa, /ə/) เช่น a ใน about ที่แทบไม่มีเสียงชัด ภาษาสเปนไม่มีการลดรูปแบบนี้เลย — สระตัวไหนเขียนอย่างไรก็ออกเสียงแบบนั้นเสมอ ไม่ว่าจะเน้นเสียงหรือไม่',
      'l3':
          'ข้อควรระวัง: เมื่อสระสองตัวมาอยู่ติดกันในพยางค์เดียว (เช่น ai, ue) จะกลายเป็นเสียงสระประสม (diphthong) ซึ่งเป็นเรื่องที่จะเรียนแยกในบทถัดๆ ไป บทนี้สอนเฉพาะสระเดี่ยวที่มั่นคงก่อน',
      'spain_note': null,
      'thai_contrast':
          'ภาษาไทยก็มีระบบสระที่ค่อนข้างคงที่เหมือนกัน (ต่างจากภาษาอังกฤษ) จึงเป็นข้อได้เปรียบของผู้เรียนไทย — สิ่งที่ต้องระวังคือไม่เผลอออกเสียงสระสเปนแบบลดรูปตามความเคยชินจากภาษาอังกฤษที่เคยเรียนมาก่อน และไม่ใส่วรรณยุกต์แบบไทยเข้าไปในคำสเปน เพราะภาษาสเปนไม่มีวรรณยุกต์ มีแต่การเน้นพยางค์ (stress)',
    },
    '11111111-1111-4111-8111-111111111105': {
      'id': '11111111-1111-4111-8111-111111111105',
      'slug': 'c_z_distincion',
      'name_th': 'ทำไม z และ c บางตัวออกเสียงเป็น th',
      'name_es': 'La distinción',
      'l1':
          'ในภาษาสเปนแบบสเปน ตัวอักษร z ทุกตำแหน่ง และ c หน้าสระ e/i ออกเสียงเหมือน th ในภาษาอังกฤษ ไม่ใช่เสียง ส',
      'l2':
          'ปรากฏการณ์นี้เรียกว่า distinción เพราะแยกเสียง /θ/ (z, c หน้า e/i) ออกจากเสียง /s/ (s ทุกตำแหน่ง) อย่างชัดเจน เช่น caza /ˈkaθa/ (การล่าสัตว์) ต่างจาก casa /ˈkasa/ (บ้าน) ทั้งสองคำสะกดคนละแบบและออกเสียงคนละแบบ',
      'l3':
          'ข้อควรระวัง: distinción เป็นสำเนียงมาตรฐานในสเปนแผ่นดินใหญ่ส่วนใหญ่ (ยกเว้นบางพื้นที่ทางใต้ เช่น อันดาลูเซียบางส่วน) แต่ภาษาสเปนเกือบทั้งหมดในละตินอเมริกาใช้ seseo คือออกเสียง z และ c หน้า e/i เป็น /s/ เหมือนกันหมด ทำให้ casa และ caza ออกเสียงเหมือนกันในสำเนียงนั้น คอร์สนี้สอน distinción เพราะเป็นเป้าหมายการออกเสียงแบบสเปน (es-ES) ของคอร์ส',
      'spain_note':
          'เจ้าของภาษาในสเปนส่วนใหญ่ได้ยินว่า casa กับ caza เป็นคำที่ออกเสียงต่างกันชัดเจน การออกเสียงทั้งคู่เป็น ส เหมือนกันอาจฟังดูเป็นสำเนียงละตินอเมริกา',
      'thai_contrast':
          'ภาษาไทยไม่มีเสียง th แบบลิ้นแตะฟัน (dental fricative) แต่มีตำแหน่งลิ้นที่ใกล้เคียงในเสียง ท ที่ไม่มีลมออก ผู้เรียนไทยจึงมักออกเสียง z/c(e,i) เป็น ส หรือ ท ไปเลย ต้องฝึกให้ปลายลิ้นแตะฟันบนแทน',
    },
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
    // hear and choose: described rather than played, since no audio asset is
    // bundled yet — the honest-unavailable state in AudioControls covers the
    // gap, this exercise just does not depend on the audio actually playing.
    '66666666-6666-4666-8666-666666666610': {
      'id': '66666666-6666-4666-8666-666666666610',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333310',
      'concept_id': '11111111-1111-4111-8111-111111111106',
      'prompt_th':
          'ลองฟังเสียงต้นแบบ (หรืออ่านลักษณะการออกเสียง) แล้วเลือกสระที่ตรงกัน: '
          'ห่อริมฝีปากให้กลมและแคบที่สุด ลิ้นอยู่สูงและด้านหลังของปาก',
      'payload': {
        'options': ['a', 'e', 'i', 'o', 'u'],
      },
      'answer_rules': {
        'accepted': ['u'],
        'accent_insensitive': true,
        'error_codes': ['PRON.VOWEL_U'],
      },
      'feedback': {
        'what_changed': 'u',
        'why_th': 'u เป็นสระที่ห่อริมฝีปากแคบและกลมที่สุด ลิ้นอยู่สูงและหลัง เช่นในคำว่า uno',
        'contrast': {'es': 'o', 'th': 'o ห่อปากกลมกว่า a แต่กว้างกว่า u'},
      },
    },
    '66666666-6666-4666-8666-666666666611': {
      'id': '66666666-6666-4666-8666-666666666611',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333311',
      'concept_id': '11111111-1111-4111-8111-111111111106',
      'prompt_th': 'ตัวอักษร e ในภาษาสเปน ออกเสียงตรงกับข้อใด',
      'payload': {
        'stem': 'e',
        'options': [
          'เอ สั้นและคงที่ ไม่ลากเสียง',
          'อี ปากยิ้มแคบ',
          'แอ ปากอ้ากว้าง',
          'เออ เสียงเบา ไม่ชัด (schwa)',
        ],
      },
      'answer_rules': {
        'accepted': ['เอ สั้นและคงที่ ไม่ลากเสียง'],
        'accent_insensitive': true,
        'error_codes': ['PRON.VOWEL_E'],
      },
      'feedback': {
        'what_changed': 'เอ สั้นและคงที่ ไม่ลากเสียง',
        'why_th':
            'สระสเปนไม่ลดรูปเป็นเสียงเบา (schwa) แบบภาษาอังกฤษ ทุกสระออกเสียงชัดและคงที่เสมอ',
        'contrast': {
          'es': 'about (EN)',
          'th': 'สระ a ในคำอังกฤษนี้ลดรูปเป็นเสียงเบา ซึ่งไม่เกิดขึ้นในภาษาสเปน',
        },
      },
    },
    '66666666-6666-4666-8666-666666666612': {
      'id': '66666666-6666-4666-8666-666666666612',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333312',
      'concept_id': '11111111-1111-4111-8111-111111111106',
      'prompt_th':
          'คำว่า "mesa" (โต๊ะ) กับ "masa" (แป้ง/มวล) พยางค์แรกออกเสียงสระเหมือนกันหรือไม่',
      'payload': {
        'stem': 'mesa / masa',
        'options': ['เหมือนกัน', 'ต่างกัน'],
      },
      'answer_rules': {
        'accepted': ['ต่างกัน'],
        'accent_insensitive': true,
        'error_codes': ['PRON.VOWEL_DISCRIMINATION'],
      },
      'feedback': {
        'what_changed': 'ต่างกัน',
        'why_th': 'mesa ขึ้นต้นด้วยสระ e ส่วน masa ขึ้นต้นด้วยสระ a ทั้งสองเป็นสระคนละเสียงและคงที่ตลอดคำ',
        'contrast': {'es': 'mesa / masa', 'th': 'โต๊ะ / แป้ง หรือ มวล'},
      },
    },
    '66666666-6666-4666-8666-666666666613': {
      'id': '66666666-6666-4666-8666-666666666613',
      'template_id': 'typed',
      'objective_id': '33333333-3333-4333-8333-333333333313',
      'concept_id': '11111111-1111-4111-8111-111111111106',
      'prompt_th': 'พิมพ์ตัวอักษรสระที่ออกเสียงเหมือนคำว่า "sí" (ใช่) — หนึ่งตัวอักษร',
      'payload': {
        'stem': 'sí → ____',
        'hint_th': 'สระตัวเดียวกับที่ออกเสียง อี',
      },
      'answer_rules': {
        'accepted': ['i'],
        'accent_insensitive': true,
        'error_codes': ['VOCAB.VOWEL_LETTER'],
      },
      'feedback': {
        'what_changed': 'i',
        'why_th': 'sí ออกเสียงด้วยสระ i เพียงตัวเดียว เป็นเสียงสั้นและแหลมที่สุดในกลุ่มสระสเปน',
        'contrast': {'es': 'sí / si', 'th': 'ใช่ / ถ้า — เขียนต่างกันที่วรรณยุกต์เขียน (tilde) เท่านั้น'},
      },
    },
    // scored_frame is what a recogniser would grade. This build has no ASR at
    // all — see speaking_view.dart — so submitting only registers attempted
    // evidence, never a verdict.
    '66666666-6666-4666-8666-666666666614': {
      'id': '66666666-6666-4666-8666-666666666614',
      'template_id': 'repeat_speech',
      'objective_id': '33333333-3333-4333-8333-333333333314',
      'concept_id': '11111111-1111-4111-8111-111111111106',
      'prompt_th': 'กดปุ่มไมค์แล้วอ่านออกเสียงสระทั้งห้าตัวให้ชัดเจนทีละตัว',
      'payload': {
        'es': 'a, e, i, o, u',
        'th': 'ออกเสียงให้สั้นและคงที่ทุกตัว ไม่ลากเสียงหรือเปลี่ยนเสียงกลางคำ',
        'target_slug': 'vowels_pure',
        'focus': 'aeiou',
      },
      'answer_rules': {
        'frame_pattern': r'^a',
        'min_confidence': 0.5,
        'error_codes': ['PRON.VOWELS'],
      },
      'feedback': {
        'what_changed': '',
        'why_th': 'ถ้าลากเสียงหรือเปลี่ยนเสียงกลางคำ จะฟังดูเหมือนสำเนียงภาษาอื่นที่ไม่ใช่สเปน',
        'contrast': {'es': 'a-e-i-o-u', 'th': 'ออกทีละตัวให้สั้นและชัด เว้นจังหวะระหว่างตัวเล็กน้อย'},
      },
    },
    '66666666-6666-4666-8666-666666666604': {
      'id': '66666666-6666-4666-8666-666666666604',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333305',
      'concept_id': null,
      'prompt_th': 'เพื่อนชาวสเปนทักคุณว่า “¡Hola! ¿Qué tal?” คุณควรตอบว่าอย่างไร',
      'payload': {
        'stem': '¡Hola! ¿Qué tal?',
        'options': [
          'Bien, ¿y tú?',
          'Sí, por favor',
          'Lo siento',
          'De nada',
        ],
      },
      'answer_rules': {
        'accepted': ['Bien, ¿y tú?'],
        'accent_insensitive': true,
        'error_codes': ['REG.GREETING'],
      },
      'feedback': {
        'what_changed': 'Bien, ¿y tú?',
        'why_th':
            '¿Qué tal? เป็นคำถามทักทาย ไม่ใช่คำขอ จึงตอบด้วยการบอกว่าสบายดีแล้วถามกลับ ไม่ใช่ตอบรับคำขอหรือขอบคุณ',
        'contrast': {'es': 'De nada.', 'th': 'ใช้ตอบเมื่อมีคนขอบคุณ ไม่ใช่ตอบคำทักทาย'},
      },
    },
    '66666666-6666-4666-8666-666666666605': {
      'id': '66666666-6666-4666-8666-666666666605',
      'template_id': 'typed',
      'objective_id': '33333333-3333-4333-8333-333333333306',
      'concept_id': null,
      'prompt_th': 'พิมพ์คำทักทายภาษาสเปนที่ใช้ได้ทุกช่วงเวลาของวัน (หนึ่งคำ)',
      'payload': {
        'stem': '____',
        'th': 'คำทักทายที่ได้ยินในบล็อกแรกของบทนี้',
      },
      'answer_rules': {
        'accepted': ['Hola'],
        'accent_insensitive': true,
        'error_codes': ['VOCAB.GREETING'],
      },
      'feedback': {
        'what_changed': 'Hola',
        'why_th': 'Hola ใช้ทักทายได้ทุกช่วงเวลาของวันและทุกระดับความเป็นทางการ',
        'contrast': {'es': 'Buenos días.', 'th': 'ทักทายเฉพาะช่วงเช้าเท่านั้น'},
      },
    },
    // scored_frame is what a recogniser would grade. This build has no ASR at
    // all — see speaking_view.dart — so submitting only registers attempted
    // evidence, never a verdict.
    '66666666-6666-4666-8666-666666666606': {
      'id': '66666666-6666-4666-8666-666666666606',
      'template_id': 'repeat_speech',
      'objective_id': '33333333-3333-4333-8333-333333333307',
      'concept_id': '11111111-1111-4111-8111-111111111105',
      'prompt_th': 'กดปุ่มไมค์แล้วพูดว่า “Gracias”',
      'payload': {
        'es': 'Gracias',
        'th': 'ออกเสียง c ให้เป็นเสียง th แบบสเปน ปลายลิ้นแตะฟันบน',
        'target_slug': 'c_z_distincion',
        'focus': 'c',
      },
      'answer_rules': {
        'frame_pattern': r'^gracias\b',
        'min_confidence': 0.55,
        'error_codes': ['PRON.C_Z_DISTINCION'],
      },
      'feedback': {
        'what_changed': '',
        'why_th': 'ถ้าออกเสียง c เป็น ส แทนที่จะเป็น th จะฟังดูเหมือนสำเนียงละตินอเมริกา ไม่ใช่ผิดความหมาย แต่ต่างจากเป้าหมายการออกเสียงของคอร์สนี้',
        'contrast': {'es': 'casa / caza', 'th': 'บ้าน / การล่าสัตว์'},
      },
    },
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
