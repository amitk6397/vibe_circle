export type LoginForm = {
  email: string;
  password: string;
};

export type RegisterForm = LoginForm & {
  name: string;
  age: string;
};
