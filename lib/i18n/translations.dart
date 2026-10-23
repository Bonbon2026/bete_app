enum AppLang { en, am, om }

class Dict {
  final String welcome;
  final String createAccount;
  final String motto;
  final String logIn;
  final String signUp;
  final String alreadyHaveAccount;
  final String dontHaveAccount;

  const Dict({
    required this.welcome,
    required this.createAccount,
    required this.motto,
    required this.logIn,
    required this.signUp,
    required this.alreadyHaveAccount,
    required this.dontHaveAccount,
  });
}

const Map<AppLang, Dict> translations = {
  AppLang.en: Dict(
    welcome: 'Welcome',
    createAccount: 'Create an account',
    motto: 'Move into what matters',
    logIn: 'Log In',
    signUp: 'Sign Up',
    alreadyHaveAccount: 'Already have an account? Log in',
    dontHaveAccount: "Don't have an account? Sign up",
  ),
  AppLang.am: Dict(
    welcome: 'እንኳን ደህና መጡ',
    createAccount: 'መለያ ይፍጠሩ',
    motto: 'ወደ ማትሬ ተንቀሳቀስ',
    logIn: 'ግባ',
    signUp: 'ተመዝገብ',
    alreadyHaveAccount: 'መለያ አለዎት? ይግቡ',
    dontHaveAccount: 'መለያ የለዎትም? ይመዝገቡ',
  ),
  AppLang.om: Dict(
    welcome: 'Baga nagaan dhuftan',
    createAccount: 'Akkaawuntii uumi',
    motto: "Gara waan barbaachisuutti deemi",
    logIn: 'Seeni',
    signUp: 'Galmaa\'i',
    alreadyHaveAccount: 'Akkaawuntii qabduu? Seeni',
    dontHaveAccount: "Akkaawuntii hin qabdu? Galmaa'i",
  ),
};
