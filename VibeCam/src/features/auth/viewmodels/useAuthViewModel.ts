import { useAppStore } from '../../../store/useAppStore';
import { isEmail, passwordError, requiredTextError } from '../../../utils/validation';
import { LoginForm, RegisterForm } from '../models/AuthForm';

export function useAuthViewModel() {
  const authenticated = useAppStore((state) => state.authenticated);
  const profile = useAppStore((state) => state.profile);

  const validateLogin = (form: LoginForm) => {
    if (!isEmail(form.email)) return 'Enter a valid email address.';
    return passwordError(form.password);
  };

  const validateRegistration = (form: RegisterForm) => {
    const nameError = requiredTextError(form.name, 'Name');
    if (nameError) return nameError;
    const age = Number(form.age);
    if (!Number.isFinite(age) || age < 18)
      return 'VibeCircle is available only for adults aged 18+.';
    return validateLogin(form);
  };

  return {
    authenticated,
    profile,
    login: useAppStore.getState().login,
    logout: useAppStore.getState().logout,
    updateProfile: useAppStore.getState().updateProfile,
    validateLogin,
    validateRegistration,
  };
}
