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
///
/// STABLE — never change these. `kLessonFoundation0L1Id` was originally the
/// *first* Foundation 0 lesson; it is not conversational-content-first any
/// more (see product rule: Foundation 0 teaches letters/sounds/reading before
/// any greeting, and only Pre-A1 is conversational). Its id, slug and every
/// block inside it are untouched — only its course-position moved, via the
/// unit's `sections`/`lessons` ordering below, to a "bonus" slot after the
/// sound-and-reading curriculum.
const String kUnitFoundation0Id = '22222222-2222-4222-8222-222222222200';
const String kLessonFoundation0L1Id = '44444444-4444-4444-8444-444444444401';
const String kLessonFoundation0L1Slug = 'foundation-0-l1';

/// Foundation 0, Section 1 — รู้จักตัวอักษร (the alphabet). The learner's
/// actual first lesson in course order now.
const String kLessonFoundation0S1Id = '44444444-4444-4444-8444-444444444410';
const String kLessonFoundation0S1Slug = 'foundation-0-s1-letters';

/// Foundation 0, Section 2 — สระ (vowels). Ships with exactly one vowel (a)
/// authored end-to-end as the reusable reference pattern; e/i/o/u follow in a
/// later change once this pattern is reviewed.
const String kLessonFoundation0S2Id = '44444444-4444-4444-8444-444444444420';
const String kLessonFoundation0S2Slug = 'foundation-0-s2-vowel-a';

/// Lesson slugs with a real, content-complete pack entry. A unit can legally
/// list a lesson stub that is not in here yet — QA-incomplete content is
/// shown but never made to look tappable (see CourseMapScreen/UnitScreen).
const Set<String> kAvailableLessonSlugs = {
  'pre-a1-u1-l3',
  kLessonFoundation0L1Slug,
  kLessonFoundation0S1Slug,
  kLessonFoundation0S2Slug,
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
      'title_th': 'Foundation 0 · เสียงและการอ่าน',
      'title_es': 'Fundamentos: sonidos y lectura',
      'subtitle_th':
          'ก่อนเริ่มภาษาสเปนจริง ปูพื้นตัวอักษร เสียง และการอ่านให้แน่นก่อน '
          'เรียนจบหมวดนี้แล้วค่อยไปทักทายและแนะนำตัวใน Pre-A1',
      // Order here IS the learning order (see
      // LocalLearnerRepository.dailyPlan in local_repositories.dart, which
      // walks this array as-is): letters, then vowels, with the original
      // conversational lesson moved to a bonus slot at the end — never in
      // front of the sound curriculum.
      'lessons': [
        {
          'id': kLessonFoundation0S1Id,
          'slug': kLessonFoundation0S1Slug,
          'title_th': 'รู้จักตัวอักษรภาษาสเปน',
          'title_es': 'El alfabeto español',
          'sort_order': 1,
          'estimated_minutes': 8,
        },
        {
          'id': kLessonFoundation0S2Id,
          'slug': kLessonFoundation0S2Slug,
          'title_th': 'เสียงสระ a',
          'title_es': 'La vocal a',
          'sort_order': 2,
          'estimated_minutes': 7,
        },
        {
          'id': kLessonFoundation0L1Id,
          'slug': kLessonFoundation0L1Slug,
          'title_th': 'สวัสดีแบบสเปน',
          'title_es': 'Hola, ¿qué tal?',
          'sort_order': 100,
          'estimated_minutes': 6,
        },
      ],
      // The Foundation 0 course map (see CourseMapScreen). Sections 3-10 have
      // no `lesson_slugs` yet — deliberately not stubbed with placeholder
      // lessons (see CLAUDE.md: never fabricate lesson content). They render
      // as "เร็วๆ นี้" until authored in a follow-up change, per the review
      // gate on this first slice (Section 1, Section 2/vowel-a only).
      'sections': [
        {
          'id': 'foundation-0-section-1',
          'title_th': '01 · รู้จักตัวอักษร',
          'description_th': 'ตัวอักษร A-Z และ Ñ ตัวพิมพ์ใหญ่ พิมพ์เล็ก และชื่อตัวอักษร',
          'sort_order': 1,
          'lesson_slugs': [kLessonFoundation0S1Slug],
        },
        {
          'id': 'foundation-0-section-2',
          'title_th': '02 · สระ',
          'description_th':
              'เสียงสระทั้ง 5 เสียงทีละตัว พร้อมคำอ่านช่วยภาษาไทย',
          'sort_order': 2,
          'lesson_slugs': [kLessonFoundation0S2Slug],
        },
        {
          'id': 'foundation-0-section-3',
          'title_th': '03 · พยัญชนะพื้นฐาน',
          'description_th': 'เสียงพยัญชนะที่ออกเสียงตรงไปตรงมา เช่น m n p t',
          'sort_order': 3,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-section-4',
          'title_th': '04 · ตัวอักษรที่เปลี่ยนเสียง',
          'description_th': 'ทำไม c และ g ออกเสียงไม่เหมือนกันทุกครั้ง',
          'sort_order': 4,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-section-5',
          'title_th': '05 · ตัวพิเศษและตัวควบ',
          'description_th': 'ตัวอักษรเฉพาะของสเปน เช่น ch ll rr qu gu ñ',
          'sort_order': 5,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-section-6',
          'title_th': '06 · อ่านพยางค์',
          'description_th': 'ประกอบเสียงตัวอักษรให้เป็นพยางค์แรกของคุณ',
          'sort_order': 6,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-section-7',
          'title_th': '07 · สระประสม',
          'description_th': 'เมื่อสระสองตัวมาอยู่ด้วยกันในคำเดียว',
          'sort_order': 7,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-section-8',
          'title_th': '08 · การลงเสียง',
          'description_th': 'รู้ว่าจะเน้นเสียงตรงไหน และเครื่องหมาย ́ บอกอะไร',
          'sort_order': 8,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-section-9',
          'title_th': '09 · อ่านคำจริง',
          'description_th': 'อ่านคำศัพท์ที่คุ้นเคยด้วยตัวเอง',
          'sort_order': 9,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-section-10',
          'title_th': '10 · อ่านวลีและประโยค',
          'description_th': 'อ่านวลีและประโยคสั้น ๆ แบบเต็มรูปแบบ',
          'sort_order': 10,
          'lesson_slugs': <String>[],
        },
        {
          'id': 'foundation-0-bonus',
          'title_th': 'โบนัส · บทสนทนาแรก',
          'description_th':
              'ทักทายแบบสเปนสั้น ๆ ระหว่างทาง — เรียนได้ตอนไหนก็ได้ ไม่ต้องรอจนจบทั้ง 10 หมวด',
          'sort_order': 100,
          'lesson_slugs': [kLessonFoundation0L1Slug],
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
    kLessonFoundation0S1Id: {
      'id': kLessonFoundation0S1Id,
      'version_id': '55555555-5555-4555-8555-555555555510',
      'slug': kLessonFoundation0S1Slug,
      'title_th': 'รู้จักตัวอักษรภาษาสเปน',
      'title_es': 'El alfabeto español',
      'goal_th':
          'เรียนจบบทนี้ คุณจะรู้จักตัวอักษรภาษาสเปนทั้ง 27 ตัว ทั้งตัวพิมพ์ใหญ่และพิมพ์เล็ก และบอกชื่อตัวอักษรที่มีเฉพาะในภาษาสเปนได้',
      'estimated_minutes': 8,

      'completion_rules': {
        'required_correct_exercises': [
          '66666666-6666-4666-8666-666666666610',
          '66666666-6666-4666-8666-666666666611',
        ],
        'required_speech_exercises': ['66666666-6666-4666-8666-666666666612'],
        'min_blocks_viewed': 8,
      },

      'blocks': [
        {
          'id': 'blk-s1-01',
          'sort_order': 1,
          'block_type': 'heading',
          'payload': {'th': 'ก่อนอ่านภาษาสเปนได้ ต้องรู้จักตัวอักษรก่อน'},
        },
        {
          'id': 'blk-s1-02',
          'sort_order': 2,
          'block_type': 'explanation',
          'concept_id': '11111111-1111-4111-8111-111111111110',
          'why_l1_th':
              'ตัวอักษรคือสัญลักษณ์ที่ใช้แทนเสียงพูด เมื่อนำตัวอักษรมาเรียงต่อกันจะกลายเป็นคำที่อ่านออกเสียงได้',
          'payload': {
            'title_th': 'ตัวอักษรคืออะไร',
            'th':
                'ตัวอักษร (letra) คือสัญลักษณ์ที่ใช้แทนเสียงพูด เมื่อนำตัวอักษรหลายตัวมาเรียงต่อกัน จะกลายเป็นคำที่อ่านออกเสียงได้ ภาษาสเปนใช้ตัวอักษรคล้ายภาษาอังกฤษมาก แต่มีตัวพิเศษเพิ่มมาอีกหนึ่งตัวคือ ñ ทำให้ภาษาสเปนมีตัวอักษรทั้งหมด 27 ตัว',
          },
        },
        {
          'id': 'blk-s1-03',
          'sort_order': 3,
          'block_type': 'explanation',
          'payload': {
            'title_th': 'ตัวพิมพ์ใหญ่กับตัวพิมพ์เล็ก',
            'th':
                'ตัวอักษรแต่ละตัวเขียนได้สองแบบ: ตัวพิมพ์ใหญ่ (เช่น A) กับตัวพิมพ์เล็ก (เช่น a) รูปร่างต่างกัน แต่เป็น "ตัวอักษรเดียวกัน" และแทนเสียงเดียวกัน ตัวพิมพ์ใหญ่มักใช้ขึ้นต้นประโยคหรือชื่อเฉพาะ ส่วนตัวพิมพ์เล็กใช้ในคำทั่วไป',
          },
        },
        {
          'id': 'blk-s1-04',
          'sort_order': 4,
          'block_type': 'alphabet_grid',
          'why_l1_th':
              'ตัวอักษร ñ (เอญเญ) เป็นตัวเดียวที่ไม่มีในภาษาอังกฤษ ออกเสียงคล้าย ญ ในภาษาไทย และทำให้คำอย่าง año (ปี) ต่างจาก ano (คำหยาบ) โดยสิ้นเชิง',
          'payload': {
            'intro_note_th':
                'คำอ่านภาษาไทยด้านล่างเป็นการเทียบเสียงคร่าว ๆ เพื่อช่วยจำชื่อตัวอักษรเท่านั้น ไม่ใช่เสียงที่ตรงกันทุกประการ',
            'audio': {
              'normal': 'foundation-0/s1/alphabet-recitation-normal.m4a',
              'slow': 'foundation-0/s1/alphabet-recitation-slow.m4a',
            },
            'letters': [
              {'upper': 'A', 'lower': 'a', 'name_es': 'a', 'name_th': 'อา'},
              {'upper': 'B', 'lower': 'b', 'name_es': 'be', 'name_th': 'เบ'},
              {'upper': 'C', 'lower': 'c', 'name_es': 'ce', 'name_th': 'เซ'},
              {'upper': 'D', 'lower': 'd', 'name_es': 'de', 'name_th': 'เด'},
              {'upper': 'E', 'lower': 'e', 'name_es': 'e', 'name_th': 'เอ'},
              {'upper': 'F', 'lower': 'f', 'name_es': 'efe', 'name_th': 'เอเฟะ'},
              {'upper': 'G', 'lower': 'g', 'name_es': 'ge', 'name_th': 'เค'},
              {'upper': 'H', 'lower': 'h', 'name_es': 'hache', 'name_th': 'อาเช่'},
              {'upper': 'I', 'lower': 'i', 'name_es': 'i', 'name_th': 'อี'},
              {'upper': 'J', 'lower': 'j', 'name_es': 'jota', 'name_th': 'โคตา'},
              {'upper': 'K', 'lower': 'k', 'name_es': 'ka', 'name_th': 'กา'},
              {'upper': 'L', 'lower': 'l', 'name_es': 'ele', 'name_th': 'เอเล'},
              {'upper': 'M', 'lower': 'm', 'name_es': 'eme', 'name_th': 'เอเม'},
              {'upper': 'N', 'lower': 'n', 'name_es': 'ene', 'name_th': 'เอเน'},
              {'upper': 'Ñ', 'lower': 'ñ', 'name_es': 'eñe', 'name_th': 'เอญเญ'},
              {'upper': 'O', 'lower': 'o', 'name_es': 'o', 'name_th': 'โอ'},
              {'upper': 'P', 'lower': 'p', 'name_es': 'pe', 'name_th': 'เป'},
              {'upper': 'Q', 'lower': 'q', 'name_es': 'cu', 'name_th': 'กู'},
              {'upper': 'R', 'lower': 'r', 'name_es': 'erre', 'name_th': 'เอเร่'},
              {'upper': 'S', 'lower': 's', 'name_es': 'ese', 'name_th': 'เอเซะ'},
              {'upper': 'T', 'lower': 't', 'name_es': 'te', 'name_th': 'เต'},
              {'upper': 'U', 'lower': 'u', 'name_es': 'u', 'name_th': 'อู'},
              {'upper': 'V', 'lower': 'v', 'name_es': 'uve', 'name_th': 'อูเบะ'},
              {
                'upper': 'W',
                'lower': 'w',
                'name_es': 'uve doble',
                'name_th': 'อูเบะโดเบล',
              },
              {'upper': 'X', 'lower': 'x', 'name_es': 'equis', 'name_th': 'เอกิส'},
              {'upper': 'Y', 'lower': 'y', 'name_es': 'ye', 'name_th': 'เย'},
              {'upper': 'Z', 'lower': 'z', 'name_es': 'zeta', 'name_th': 'เซตะ'},
            ],
          },
        },
        {
          'id': 'blk-s1-05',
          'sort_order': 5,
          'block_type': 'exercise_embed',
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666610'},
        },
        {
          'id': 'blk-s1-06',
          'sort_order': 6,
          'block_type': 'exercise_embed',
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666611'},
        },
        {
          'id': 'blk-s1-07',
          'sort_order': 7,
          'block_type': 'exercise_embed',
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666612'},
        },
        {
          'id': 'blk-s1-08',
          'sort_order': 8,
          'block_type': 'review',
          'payload': {
            'title_th': 'สรุปบทนี้',
            'points_th': [
              'ภาษาสเปนมีตัวอักษร 27 ตัว รวม ñ ที่ไม่มีในภาษาอังกฤษ',
              'ตัวพิมพ์ใหญ่กับตัวพิมพ์เล็กคือตัวอักษรเดียวกัน',
              'ตัวอักษรแต่ละตัวมีชื่อของตัวเอง แยกจากเสียงที่มันแทน',
            ],
            'th': 'ตอนนี้คุณรู้จักตัวอักษรภาษาสเปนครบทั้ง 27 ตัวแล้ว พร้อมไปเรียนเสียงสระต่อ',
          },
        },
      ],
    },
    kLessonFoundation0S2Id: {
      'id': kLessonFoundation0S2Id,
      'version_id': '55555555-5555-4555-8555-555555555520',
      'slug': kLessonFoundation0S2Slug,
      'title_th': 'เสียงสระ a',
      'title_es': 'La vocal a',
      'goal_th':
          'เรียนจบบทนี้ คุณจะออกเสียงสระ a แบบสเปนได้ แยกเสียง a ได้ยินจากเสียงอื่น และแยกคำว่า casa เป็นพยางค์ได้',
      'estimated_minutes': 7,

      'completion_rules': {
        'required_correct_exercises': [
          '66666666-6666-4666-8666-666666666620',
          '66666666-6666-4666-8666-666666666621',
        ],
        'required_speech_exercises': ['66666666-6666-4666-8666-666666666623'],
        'min_blocks_viewed': 8,
      },

      'blocks': [
        {
          'id': 'blk-s2a-01',
          'sort_order': 1,
          'block_type': 'heading',
          'payload': {'th': 'สระตัวแรก: a'},
        },
        {
          'id': 'blk-s2a-02',
          'sort_order': 2,
          'block_type': 'explanation',
          'concept_id': '11111111-1111-4111-8111-111111111110',
          'why_l1_th':
              'สระคือเสียงที่ลมออกจากปากได้อย่างอิสระ ไม่มีลิ้น ฟัน หรือริมฝีปากมากั้น ภาษาสเปนมีสระ 5 เสียงคือ a e i o u',
          'payload': {
            'title_th': 'สระคืออะไร',
            'th':
                'สระ (vocal) คือเสียงที่ลมออกจากปากได้อย่างอิสระ ไม่มีอะไรมากั้นทางเดินลม ภาษาสเปนมีสระอยู่ 5 เสียงเท่านั้นคือ a e i o u และแต่ละตัวออกเสียงคงที่เสียงเดียวเสมอ ไม่เปลี่ยนไปเป็นเสียงอื่นเหมือนภาษาอังกฤษ (เช่น a ในคำว่า cat, ate, about ออกเสียงต่างกันหมด แต่ a ในภาษาสเปนออกเสียงเดียวตลอด)',
          },
        },
        {
          'id': 'blk-s2a-03',
          'sort_order': 3,
          'block_type': 'pronunciation_guide',
          'concept_id': null,
          'why_l1_th':
              'สระ a ในภาษาสเปนอ้าปากกว้างกว่าสระ อะ ในภาษาไทย และไม่มีการลากเสียงสั้น-ยาวแบบภาษาไทย',
          'payload': {
            'target_slug': 'vowel_a',
            'focus': 'A a',
            'ipa_phonemic': 'a',
            'note_th':
                'อ้าปากกว้าง ลิ้นอยู่ต่ำและกลางปาก ริมฝีปากไม่ห่อ เสียงสั้น กระชับ และคงที่ทุกครั้งที่เจอ ไม่ว่า a จะอยู่ตำแหน่งไหนของคำ',
            'thai_helper_th': 'อา',
            'example_es': 'casa',
            'example_meaning_th': 'บ้าน',
            'example_reading_th': 'กา-ซา',
            'example_syllables': ['ca', 'sa'],
            'show_spain_badge': false,
            'audio': {
              'normal': 'foundation-0/s2/vowel-a-normal.m4a',
              'slow': 'foundation-0/s2/vowel-a-slow.m4a',
            },
          },
        },
        {
          'id': 'blk-s2a-04',
          'sort_order': 4,
          'block_type': 'exercise_embed',
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666620'},
        },
        {
          'id': 'blk-s2a-05',
          'sort_order': 5,
          'block_type': 'exercise_embed',
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666621'},
        },
        {
          'id': 'blk-s2a-06',
          'sort_order': 6,
          'block_type': 'exercise_embed',
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666622'},
        },
        {
          'id': 'blk-s2a-07',
          'sort_order': 7,
          'block_type': 'exercise_embed',
          'payload': {'exercise_id': '66666666-6666-4666-8666-666666666623'},
        },
        {
          'id': 'blk-s2a-08',
          'sort_order': 8,
          'block_type': 'review',
          'payload': {
            'title_th': 'สรุปบทนี้',
            'points_th': [
              'สระ a ออกเสียงคงที่เสียงเดียวเสมอ ไม่เปลี่ยนไปเป็นเสียงอื่น',
              'คำอ่านไทย “อา” เป็นสะพานช่วยจำ ไม่ใช่เสียงที่เหมือนกันทุกประการ',
              'casa แยกเป็น 2 พยางค์: ca-sa',
            ],
            'th': 'ตอนนี้คุณออกเสียงสระ a แบบสเปนและแยกพยางค์ของ casa ได้แล้ว',
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
    '11111111-1111-4111-8111-111111111110': {
      'id': '11111111-1111-4111-8111-111111111110',
      'slug': 'what_is_a_letter_sound',
      'name_th': 'ตัวอักษร สระ พยัญชนะ คืออะไร',
      'name_es': 'Letras, vocales y consonantes',
      'l1':
          'ตัวอักษรคือสัญลักษณ์แทนเสียง สระคือเสียงที่ลมออกได้อย่างอิสระ ส่วนพยัญชนะคือเสียงที่มีบางส่วนของปากมากั้นทางเดินลม',
      'l2':
          'ภาษาสเปนมีตัวอักษร 27 ตัว แบ่งเป็นสระ 5 ตัว (a e i o u) และพยัญชนะ 22 ตัว สระในภาษาสเปนออกเสียงคงที่เสมอ ต่างจากภาษาอังกฤษที่สระตัวเดียวกันออกเสียงได้หลายแบบขึ้นกับคำ',
      'l3':
          'ข้อควรระวัง: ตัวอักษรกับเสียงไม่ได้ตรงกันเสมอไปแบบหนึ่งต่อหนึ่ง เช่น c และ g เปลี่ยนเสียงตามสระที่ตามมา (ca/co/cu ต่างจาก ce/ci) และบางตัวอักษรอย่าง h ไม่ออกเสียงเลย เนื้อหาส่วนนี้จะค่อย ๆ อธิบายทีละกรณีในบทถัดไป ไม่สอนรวดเดียวทั้งหมด',
      'spain_note': null,
      'thai_contrast':
          'ภาษาไทยก็แบ่งสระกับพยัญชนะเหมือนกัน แต่สระไทยมีทั้งสระเสียงสั้นและยาว (อะ/อา) ส่วนสระสเปนไม่มีการลากเสียงสั้น-ยาวแบบนั้น การอ่านสระสเปนจึงควรอ่านสั้น กระชับ เท่ากันทุกครั้ง',
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
    '66666666-6666-4666-8666-666666666610': {
      'id': '66666666-6666-4666-8666-666666666610',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333310',
      'concept_id': null,
      'prompt_th': 'ตัวพิมพ์เล็กของตัวอักษร “M” คือข้อใด',
      'payload': {
        'stem': 'M',
        'options': ['m', 'n', 'w', 'ñ'],
      },
      'answer_rules': {
        'accepted': ['m'],
        'accent_insensitive': true,
        'error_codes': ['LETTER.CASE'],
      },
      'feedback': {
        'what_changed': 'm',
        'why_th':
            'M ตัวพิมพ์ใหญ่กับ m ตัวพิมพ์เล็กคือตัวอักษรเดียวกัน แค่รูปร่างต่างกันตามตำแหน่งที่ใช้',
        'contrast': {'es': 'N n', 'th': 'คนละตัวอักษรกับ M m'},
      },
    },
    '66666666-6666-4666-8666-666666666611': {
      'id': '66666666-6666-4666-8666-666666666611',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333311',
      'concept_id': null,
      'prompt_th': 'ตัวอักษรตัวใดที่มีเฉพาะในภาษาสเปน ไม่มีในภาษาอังกฤษ',
      'payload': {
        'stem': '¿Cuál letra es exclusiva del español?',
        'options': ['ñ', 'k', 'w', 'x'],
      },
      'answer_rules': {
        'accepted': ['ñ'],
        'accent_insensitive': false,
        'error_codes': ['LETTER.SPANISH_ONLY'],
      },
      'feedback': {
        'what_changed': 'ñ',
        'why_th':
            'ñ (เอญเญ) เป็นตัวอักษรเดียวที่ไม่มีในภาษาอังกฤษ และทำให้คำอย่าง año (ปี) ต่างจากคำอื่นที่สะกดคล้ายกันแต่ไม่มี ñ',
        'contrast': {'es': 'k, w, x', 'th': 'มีอยู่แล้วในภาษาอังกฤษ (ใช้น้อยในคำสเปนแท้)'},
      },
    },
    // scored_frame is what a recogniser would grade. This build has no ASR at
    // all — see speaking_view.dart — so submitting only registers attempted
    // evidence, never a verdict.
    '66666666-6666-4666-8666-666666666612': {
      'id': '66666666-6666-4666-8666-666666666612',
      'template_id': 'repeat_speech',
      'objective_id': '33333333-3333-4333-8333-333333333312',
      'concept_id': null,
      'prompt_th': 'กดปุ่มไมค์แล้วออกเสียงชื่อตัวอักษร “ñ”',
      'payload': {
        'es': 'eñe',
        'th': 'ออกเสียงคล้าย เอ-ญเญ ลิ้นแตะเพดานปาก',
        'target_slug': 'letter_name_ene',
        'focus': 'ñ',
      },
      'answer_rules': {
        'frame_pattern': r'^e\s*ñ?e$',
        'min_confidence': 0.5,
        'error_codes': ['PRON.ENE'],
      },
      'feedback': {
        'what_changed': '',
        'why_th': 'ชื่อของตัวอักษร ñ คือ “eñe” แยกจากเสียงที่มันแทนในคำ (เช่นใน año)',
        'contrast': {'es': 'n / ñ', 'th': 'คนละตัวอักษรและคนละเสียงกัน'},
      },
    },
    '66666666-6666-4666-8666-666666666620': {
      'id': '66666666-6666-4666-8666-666666666620',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333320',
      'concept_id': null,
      'prompt_th': 'ฟังเสียง /a/ แล้วเลือกตัวอักษรที่ตรงกับเสียงที่ได้ยิน',
      'payload': {
        'stem': '/a/',
        'options': ['a', 'e', 'i', 'o'],
      },
      'answer_rules': {
        'accepted': ['a'],
        'accent_insensitive': true,
        'error_codes': ['VOWEL.HEAR_CHOOSE'],
      },
      'feedback': {
        'what_changed': 'a',
        'why_th': 'เสียง /a/ อ้าปากกว้างที่สุดในบรรดาสระทั้ง 5 เสียงของภาษาสเปน',
        'contrast': {'es': 'e, i, o, u', 'th': 'อ้าปากแคบกว่าหรือห่อริมฝีปาก'},
      },
    },
    '66666666-6666-4666-8666-666666666621': {
      'id': '66666666-6666-4666-8666-666666666621',
      'template_id': 'mcq',
      'objective_id': '33333333-3333-4333-8333-333333333321',
      'concept_id': null,
      'prompt_th': 'แยกคำว่า “casa” เป็นพยางค์ให้ถูกต้อง',
      'payload': {
        'stem': 'casa',
        'options': ['ca-sa', 'cas-a', 'c-asa'],
      },
      'answer_rules': {
        'accepted': ['ca-sa'],
        'accent_insensitive': true,
        'error_codes': ['SYLLABLE.SPLIT'],
      },
      'feedback': {
        'what_changed': 'ca-sa',
        'why_th':
            'ภาษาสเปนมักแบ่งพยางค์ตรงพยัญชนะที่ตามด้วยสระ: c-a และ s-a จึงรวมเป็น ca-sa',
        'contrast': {'es': 'cas-a', 'th': 'แบ่งผิดตำแหน่ง ไม่ตรงกับการออกเสียงจริง'},
      },
    },
    '66666666-6666-4666-8666-666666666622': {
      'id': '66666666-6666-4666-8666-666666666622',
      'template_id': 'typed',
      'objective_id': '33333333-3333-4333-8333-333333333322',
      'concept_id': null,
      'prompt_th': 'พิมพ์สระที่ปรากฏซ้ำสองครั้งในคำว่า “casa”',
      'payload': {
        'stem': 'c_s_',
        'th': 'ตัวเดียว ปรากฏสองครั้งในคำนี้',
      },
      'answer_rules': {
        'accepted': ['a'],
        'accent_insensitive': true,
        'error_codes': ['VOWEL.IDENTIFY'],
      },
      'feedback': {
        'what_changed': 'a',
        'why_th': 'casa สะกดด้วย c-a-s-a สระ a ปรากฏสองครั้งและออกเสียงเหมือนกันทุกครั้ง',
        'contrast': {'es': 'e / i / o / u', 'th': 'ไม่ปรากฏในคำนี้'},
      },
    },
    // scored_frame is what a recogniser would grade. This build has no ASR at
    // all — see speaking_view.dart — so submitting only registers attempted
    // evidence, never a verdict.
    '66666666-6666-4666-8666-666666666623': {
      'id': '66666666-6666-4666-8666-666666666623',
      'template_id': 'repeat_speech',
      'objective_id': '33333333-3333-4333-8333-333333333323',
      'concept_id': null,
      'prompt_th': 'กดปุ่มไมค์แล้วพูดว่า “casa”',
      'payload': {
        'es': 'casa',
        'th': 'อ้าปากกว้างตอนออกเสียง a ทั้งสองครั้ง เสียงสั้นและคงที่',
        'target_slug': 'vowel_a',
        'focus': 'a',
      },
      'answer_rules': {
        'frame_pattern': r'^casa\b',
        'min_confidence': 0.5,
        'error_codes': ['PRON.VOWEL_A'],
      },
      'feedback': {
        'what_changed': '',
        'why_th': 'สระ a ในภาษาสเปนออกเสียงคงที่ทุกครั้ง ไม่ว่าจะอยู่ตำแหน่งไหนของคำ',
        'contrast': {'es': 'casa / caza', 'th': 'บ้าน / การล่าสัตว์ (เสียง c ต่างกัน ไม่ใช่ a)'},
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
