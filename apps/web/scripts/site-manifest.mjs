export const HOST = 'https://secretmsg.net';
export const DEFAULT_IMAGE = `${HOST}/logo.svg`;

export const canonicalUrl = (path) => {
  if (path === '/') return HOST;
  return `${HOST}${path.replace(/\/+$/, '')}/`;
};

export const STATIC_ROUTES = Object.freeze([
  {
    path: '/',
    title: 'SecretMsg - Send & Receive Anonymous Messages',
    description: 'Send and receive honest, private anonymous messages with your personalized secretmsg.net link. Safe, fast, and open source.',
    type: 'WebSite',
  },
  {
    path: '/about',
    title: 'About SecretMsg - Honest Anonymous Messaging',
    description: 'Learn why SecretMsg removes the social barriers, hierarchy, and surveillance that keep people from communicating honestly.',
    type: 'WebPage',
  },
  {
    path: '/faq',
    title: 'Frequently Asked Questions - SecretMsg',
    description: 'Answers about creating your anonymous message link, sending messages, managing your board, troubleshooting, and privacy.',
    type: 'FAQPage',
  },
  {
    path: '/contact',
    title: 'Contact SecretMsg',
    description: 'Contact SecretMsg for general questions, feedback, privacy requests, legal inquiries, or urgent trust and safety concerns.',
    type: 'ContactPage',
  },
  {
    path: '/download',
    title: 'Download the SecretMsg Android App',
    description: 'Get the native SecretMsg Android app for Daily Drop, streaks, secure anonymous messages, double-blind replies, and supporter perks.',
    type: 'SoftwareApplication',
  },
  {
    path: '/supporters',
    title: 'SecretMsg Supporters',
    description: 'Learn how SecretMsg supporters help fund privacy, safety, and a better anonymous messaging experience for everyone.',
    type: 'WebPage',
  },
  {
    path: '/demo',
    title: 'SecretMsg Interactive Demo',
    description: 'Test anonymous messages, prompt roulette, story stickers, and double-blind replies in a safe interactive sandbox.',
    type: 'WebPage',
  },
  {
    path: '/dice',
    title: '3D Dice Prompt Roulette - SecretMsg',
    description: 'Roll the dice for a candid, viral, or deep anonymous message prompt, or browse the SecretMsg prompt library.',
    type: 'WebPage',
  },
  {
    path: '/sticker-studio',
    title: 'Story Sticker Studio - SecretMsg',
    description: 'Create a 9:16 story sticker for your anonymous message board with a custom theme and message prompt.',
    type: 'WebPage',
  },
  {
    path: '/login',
    title: 'Log In to SecretMsg',
    description: 'Log in to your private SecretMsg board to read anonymous messages and manage your account.',
    type: 'WebPage',
  },
  {
    path: '/delete-account',
    title: 'Delete Your SecretMsg Account',
    description: 'Permanently delete your SecretMsg account and associated account data using the public deletion request page.',
    type: 'WebPage',
  },
  {
    path: '/blog',
    title: 'SecretMsg Blog - Privacy and Anonymous Culture',
    description: 'Essays on privacy, anonymous culture, honest conversations, and getting the most out of your SecretMsg inbox.',
    type: 'Blog',
  },
  {
    path: '/p/safety',
    title: 'Safety Center & Crisis Help - SecretMsg',
    description: 'Learn about SecretMsg moderation tools, reporting procedures, digital boundaries, and immediate crisis support resources.',
    type: 'WebPage',
    component: 'SafetyPage',
  },
  {
    path: '/p/child-safety-policy',
    title: 'Child Safety Policy - SecretMsg',
    description: 'Read the SecretMsg Child Safety Policy and learn how we protect minors, respond to safety reports, and prevent child endangerment.',
    type: 'WebPage',
    component: 'ChildSafetyPage',
  },
  {
    path: '/p/approach-to-safety',
    title: 'Our Approach to Safety - SecretMsg',
    description: 'Learn how SecretMsg combines authentic connection, proactive moderation, recipient control, and community standards to create a safer platform.',
    type: 'WebPage',
    component: 'ApproachToSafetyPage',
  },
  {
    path: '/p/guide-to-online-safety',
    title: 'Guide to Online Safety - SecretMsg',
    description: 'Learn how to protect your privacy, keep anonymous conversations fun, and stay safe while connecting on SecretMsg.',
    type: 'WebPage',
    component: 'OnlineSafetyGuidePage',
  },
  {
    path: '/p/community-guidelines',
    title: 'Community Guidelines - SecretMsg',
    description: 'Read the SecretMsg community guidelines for kind, respectful, and authentic anonymous conversations.',
    type: 'WebPage',
    component: 'CommunityGuidelinesPage',
  },
  {
    path: '/p/safety-tools',
    title: 'Safety Tools & Controls - SecretMsg',
    description: 'Explore SecretMsg inbox controls for blocking abuse, filtering language, setting boundaries, and managing unwanted messages.',
    type: 'WebPage',
    component: 'SafetyToolsPage',
  },
  {
    path: '/p/resources',
    title: 'Safety & Wellbeing Resources - SecretMsg',
    description: 'Find free, confidential safety, bullying, emotional wellbeing, and crisis support resources for you or someone you know.',
    type: 'WebPage',
    component: 'SafetyResourcesPage',
  },
  {
    path: '/p/contact-us',
    title: 'Contact SecretMsg Safety Team',
    description: 'Contact the SecretMsg team for general support, privacy questions, legal requests, or urgent trust and safety assistance.',
    type: 'ContactPage',
    component: 'ContactPage',
  },
  {
    path: '/p/terms',
    title: 'Terms of Service - SecretMsg',
    description: 'Read the terms that govern access to and use of SecretMsg anonymous messaging services.',
    type: 'WebPage',
    component: 'TermsPage',
  },
  {
    path: '/p/privacy',
    title: 'Privacy Policy - SecretMsg',
    description: 'Learn how SecretMsg uses privacy as a foundational design constraint across its data, infrastructure, and services.',
    type: 'WebPage',
    component: 'PrivacyPage',
  },
  {
    path: '/p/cookies',
    title: 'Cookies & Local Storage Policy - SecretMsg',
    description: 'Learn which essential cookies and local browser storage SecretMsg uses and why it avoids invasive cross-site tracking.',
    type: 'WebPage',
    component: 'CookiesPage',
  },
  {
    path: '/p/disclaimer',
    title: 'Disclaimer - SecretMsg',
    description: 'Read SecretMsg operational disclosures, warranty disclaimers, and limitations of liability.',
    type: 'WebPage',
    component: 'DisclaimerPage',
  },
]);
