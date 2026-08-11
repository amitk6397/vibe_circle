export const isEmail = (value: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());

export const passwordError = (value: string) => {
  if (value.length < 8) return 'Password must contain at least 8 characters.';
  if (!/[A-Za-z]/.test(value) || !/\d/.test(value))
    return 'Password must include a letter and a number.';
  return '';
};

export const usernameError = (value: string) => {
  const clean = value.trim();
  if (clean.length < 3) return 'Username must contain at least 3 characters.';
  if (!/^[a-zA-Z0-9._]+$/.test(clean)) return 'Use only letters, numbers, dots, and underscores.';
  return '';
};

export const requiredTextError = (value: string, label: string, minimum = 2) =>
  value.trim().length < minimum ? `${label} must contain at least ${minimum} characters.` : '';
