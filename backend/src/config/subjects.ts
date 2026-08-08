export const CLASS_SUBJECT_MAPPING: Record<string, string[]> = {
  'Class 1': [
    'تفهيم',
  ],
  'Class 2': [
    'قرأن',
    'حفظ',
    'فقه',
    'لسان',
    'عقيدة',
    'دروس الإحسان',
  ],
  'Class 3': [
    'قرأن',
    'حفظ',
    'عقيدة',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
  ],
  'Class 4': [
    'قرأن',
    'حفظ',
    'عقيدة',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
  ],
  'Class 5': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
  ],
  'Class 6': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
    'ഉപപാഠപുസ്തകം',
  ],
  'Class 7': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
    'ഉപപാഠപുസ്തകം',
  ],
  'Class 8': [
    'قرأن',
    'حفظ',
    'تجويد',
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تريخ',
    'ഉപപാഠപുസ്തകം',
  ],
  'Class 9': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تاريخ',
  ],
  'Class 10': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تفسير',
  ],
  'Class 11': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تفسير',
  ],
  'Class 12': [
    'فقه',
    'لسان',
    'دروس الإحسان',
    'تفسير',
  ],
};

export const normalizeClassName = (input?: string | null): string => {
  if (!input || !input.trim()) return 'Class 1';
  const raw = input.trim();

  const match = raw.match(/\b(1[0-2]|[1-9])\b/);
  if (match) {
    return `Class ${match[1]}`;
  }

  for (const key of Object.keys(CLASS_SUBJECT_MAPPING)) {
    if (key.toLowerCase() === raw.toLowerCase()) {
      return key;
    }
  }

  return 'Class 1';
};

export const getSubjectsForClass = (className?: string | null): string[] => {
  const key = normalizeClassName(className);
  return CLASS_SUBJECT_MAPPING[key] || CLASS_SUBJECT_MAPPING['Class 1'];
};

export const isValidSubjectForClass = (className?: string | null, subjectName?: string | null): boolean => {
  if (!subjectName || !subjectName.trim()) return false;
  const allowed = getSubjectsForClass(className);
  const clean = subjectName.trim().toLowerCase();
  return allowed.some((s) => s.trim().toLowerCase() === clean);
};
