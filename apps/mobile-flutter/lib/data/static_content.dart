// Auto-generated from legacy-pages HTML - DO NOT EDIT MANUALLY

class StaticSection {
  final String heading;
  final List<String> body;
  const StaticSection(this.heading, this.body);
}

class StaticPageContent {
  final String title;
  final List<StaticSection> sections;
  const StaticPageContent(this.title, this.sections);
}

const Map<String, StaticPageContent> STATIC_PAGES = {
  'about': StaticPageContent('Truth Without the Friction of Identity', [
    StaticSection('Overview', [
      'When communication requires constant self-editing, important truths go unsaid. SecretMsg is built to remove the social barriers, hierarchy, and surveillance that keep people from being genuinely honest.',
    ]),
    StaticSection('psychology Why We Built SecretMsg', [
      'Modern digital tools turned communication into a performative stage. At secretmsg.net , we are giving people their authentic voice back.',
      'In typical social networks and workplace channels, every statement is permanently attached to your profile, weighed against social risk, or parsed by algorithms. The result is silent conformity: valuable workplace feedback goes withheld, heartfelt sentiments to old friends remain unsent, and sincere questions stay unasked.',
      'We created SecretMsg to prove that anonymous messaging can be a mature, high-trust utility rather than a reckless gimmick. By combining transport security, data minimization, recipient sovereignty, and rules-based safety controls, we enable purposeful honesty that strengthens human connection.',
    ]),
    StaticSection('Workplace & Peer Candor', [
      'Deliver constructive, honest feedback to teammates, founders, or mentors without navigating office politics or fearing career friction.',
    ]),
    StaticSection('Low-Pressure Reconnections', [
      'Reach out across time to someone you’ve drifted from or share a warm sentiment without the pressure or permanence of an official direct message.',
    ]),
    StaticSection('True Privacy by Design', [
      'Ask honest questions without advertising surveillance or cross-site profiling. Cloudflare processes request data to host SecretMsg, and the D1 rate-limit table uses hashed keys rather than readable IP addresses.',
    ]),
    StaticSection('Engineering Trust into Every Message', [
      'Unlike legacy platforms that treat privacy as a marketing slogan or monetize conflict with fake notification paywalls, SecretMsg is engineered from the ground up around dignity, control, and verifiable safety .',
      'We believe communication should empower honest connections rather than compromise peace of mind. Every mechanism we design is built to protect the recipient\'s well-being while giving senders a secure, low-friction channel to share what is real.',
    ]),
    StaticSection('Recipient Sovereignty', [
      'You are always in total control of your inbox. Filter custom words, delete messages, pause your link, or request account deletion with its disclosed limits.',
    ]),
    StaticSection('Double-Blind Replies', [
      'Reply directly to an anonymous question without revealing who sent it. Keep the conversation going privately and organically.',
    ]),
    StaticSection('Zero Tracking & Privacy', [
      'No invasive advertising trackers, no cross-site profiling, and no selling your personal information. Clean, straightforward, and private.',
    ]),
    StaticSection('Creative Roulette & Themes', [
      'Explore 14,000+ curated prompts across friendship, vibes, dating, and hot takes, or roll the 3D interactive Roulette when you need inspiration.',
    ]),
    StaticSection('Be REAL', [
      'Share what’s authentic. Sincerity builds trust. True connections start when people feel safe speaking honestly without judgment.',
    ]),
    StaticSection('Be KIND', [
      'Lift each other up. Use your words to celebrate friends, offer warmth, and spread positivity. Bullying and harassment have zero place here.',
    ]),
    StaticSection('Be YOU', [
      'Embrace your unique personality. Everyone’s quirks and passions make the conversation richer and more memorable.',
    ]),
    StaticSection('local_fire_department Our Community', [
      'When we started SecretMsg, we hoped it would help people connect on a deeper level. But seeing the warmth, creativity, and viral fun across social media blew us away.',
      'Every day, people use SecretMsg to learn about their friends, play Q&A games on Instagram & Snapchat, and express things they were always too shy to say in person. You make this platform amazing, and we are grateful for each and every one of you.',
    ]),
    StaticSection('We’d love to hear from you', [
      'Got ideas, feedback, partner inquiries, or just want to say hi? Use the appropriate SecretMsg contact channel.',
    ]),
  ]),
  'approach-to-safety': StaticPageContent('Our Approach to Safety', [
    StaticSection('Overview', [
      'At SecretMsg, safety is our highest priority. We created SecretMsg as a vibrant anonymous Q&A platform where you can foster authentic, meaningful connections with friends, ask fun questions, reply in public or private, and keep the conversation going — all within a community rooted in kindness and respect.',
    ]),
    StaticSection('Automated Safeguards', [
      'Message submission and abuse reporting use Cloudflare Turnstile. Recipients can also configure hidden-word filters that quarantine matching messages for review or reject them in strict mode. These are rules-based safeguards, not automated machine-learning content classification.',
    ]),
    StaticSection('Reports and Safety Contacts', [
      'In-app reports store the report reason and pending or resolved status. Email reports can be sent to safety@secretmsg.net . SecretMsg does not claim a staffed 24-hour review team.',
    ]),
    StaticSection('Recipient Sovereignty', [
      'Pause your link at any time, filter custom keywords, block unwanted senders in 1 tap, or delete individual messages from your inbox.',
    ]),
    StaticSection('Swift In-App Reporting', [
      'Reporting an uncomfortable message quarantines it and records the report. Reporting does not automatically identify, globally block, or terminate the anonymous sender.',
    ]),
    StaticSection('01 Cultivating Kindness in Anonymous Q&A', [
      'Anonymity can empower people to share candid compliments, wholesome confessions, and creative questions that they might feel too hesitant to say aloud. However, an open door must always have an ironclad shield.',
      'SecretMsg uses text-only message delivery, abuse verification, recipient controls, reporting, and block lists. You are always in control of your link, your board, and your conversations.',
    ]),
    StaticSection('02 Actual Content Moderation Architecture', [
      'We take cases of bullying, hate, or violence seriously. SecretMsg does not use automated machine-learning classification or claim that its filters understand context, slang, intent, or every form of abuse.',
      'The implemented content control is recipient-configured hidden-word matching. In standard mode, a match is quarantined for recipient review. In strict mode, the submission is rejected and quarantined.',
      'Pending reports can be reviewed and marked resolved through an operator process. This policy does not promise an immediate or 24-hour human response.',
    ]),
    StaticSection('03 How In-App Reporting & Blocking Works', [
      'When you receive a message on SecretMsg that you find inappropriate, offensive, or harmful, you can report it directly within your inbox and provide a reason:',
    ]),
    StaticSection('Q: What is and isn\'t allowed on SecretMsg?', [
      'Our Community Guidelines and Terms of Service define all prohibited behavior. In general, SecretMsg is an uplifting place to have fun, ask questions, share compliments, and create authentic Q&A threads with friends. Cyberbullying, hate speech, threats, sexual harassment, and predatory behavior are strictly prohibited.',
    ]),
    StaticSection('Q: Can I block anonymous message senders?', [
      'Yes. Select the separate block action on a message. The app-generated sender value is stored by SecretMsg only as a SHA-256 hash in that recipient\'s block list. The message is removed, and the sender is blocked from that link without revealing their identity or creating a network-wide IP block.',
    ]),
    StaticSection('Q: I received an emergency message; what should I do?', [
      'If a message suggests that you or someone else may be in imminent physical danger or crisis, contact local emergency services or law enforcement immediately. Once emergency responders are engaged, notify safety@secretmsg.net when it is safe to do so.',
    ]),
    StaticSection('Q: I received a concerning message; how do I get help?', [
      'If the message is concerning but not an immediate physical emergency, report it in your inbox or email safety@secretmsg.net with the link, relevant message details, and a safe way to contact you.',
    ]),
    StaticSection('Q: Where can I find crisis and mental health resources?', [
      'Visit our dedicated Safety & Crisis Resources page for direct hotlines, text lines, and confidential support services for mental health, anti-bullying, and crisis intervention.',
    ]),
    StaticSection('05 We Are Here to Help', [
      'No concern is too small. If you ever have a question about our safety tools or need assistance with your link:',
    ]),
  ]),
  'child-safety': StaticPageContent('Child Safety Policy', [
    StaticSection('Overview', [
      'Effective Date: June 22, 2026 • Updated September 2026',
    ]),
    StaticSection('CSAE Reporting and Required Escalation', [
      'SecretMsg prohibits Child Sexual Abuse Material (CSAM) and child sexual exploitation or abuse (CSAE). A child, parent, guardian, or any other person may report CSAE directly to the National Center for Missing & Exploited Children (NCMEC) CyberTipline. When SecretMsg obtains actual knowledge of CSAE, it will preserve relevant records and refer the matter to NCMEC and other competent authorities as required by law. The current service does not automatically detect CSAE or automatically submit reports, and SecretMsg does not claim a staffed 24-hour review team.',
    ]),
    StaticSection('01 Our Commitment', [
      'SecretMsg is committed to protecting children and minors from exploitation, abuse, and harmful content. SecretMsg is not directed to children under 13. Users aged 13–17 may use the service only with parent or legal-guardian permission and in compliance with applicable law. The current application does not use automated age assurance or age classification.',
    ]),
    StaticSection('02 Prohibited Content and Conduct', [
      'SecretMsg prohibits CSAM, grooming or predatory behavior, sexualization or exploitation of minors, and use of the service to facilitate harmful offline contact. These prohibitions apply to all users regardless of age.',
      'Depending on the evidence and applicable law, violations may result in message removal, account restriction or termination, a recipient-specific sender block, preservation of relevant records, and referral to NCMEC or law enforcement. An in-app report quarantines the message and records the report; it does not automatically reveal, globally block, or terminate the anonymous sender.',
    ]),
    StaticSection('03 Platform Design Protections', [
      'The message API is text-only and does not accept photos, videos, audio, or other media. This reduces media-based child-exploitation pathways but does not make harmful text safe.',
      'Message submission and reporting use Cloudflare Turnstile. Recipients can configure hidden-word filters: standard mode quarantines a match for review, and strict mode rejects and quarantines it. These deterministic checks are not machine-learning content classifiers and cannot identify every instance of CSAE, grooming, self-harm, or other abuse.',
      'A recipient can report a message with a reason. Reporting moves the message to quarantine. Blocking is separate: it stores the app-generated sender-fingerprint hash in that recipient\'s block list and removes the message without revealing the sender or creating a network-wide IP block.',
    ]),
    StaticSection('04 Reporting by a Child, Parent, or Guardian', [
      'Anyone may report a child-safety concern without an account by emailing safety@secretmsg.net or abuse@secretmsg.net . Include the SecretMsg link, relevant message details, the concern, and a safe contact method, but do not include unnecessary information about a child. A recipient may also report from the inbox. This policy is published at secretmsg.net/p/child-safety-policy .',
      'An in-app report stores the report reason and pending or resolved status and quarantines the message. SecretMsg does not promise a staffed 24-hour response channel or immediate human review. For immediate danger, contact local emergency services first.',
    ]),
    StaticSection('05 CSAE Escalation Path', [
      'If possible CSAM or other CSAE is identified, report it directly to the NCMEC CyberTipline at report.cybertip.org and also notify safety@secretmsg.net . Where required, use the relevant law-enforcement channel. Immediate danger should be reported to local emergency services first.',
      'When SecretMsg obtains actual knowledge of CSAE, it will preserve relevant records and refer the matter to NCMEC and other competent authorities as required by law. The current application does not automatically classify reports or automatically submit authority reports.',
    ]),
    StaticSection('06 Child Safety Point of Contact', [
      'Designated child-safety, CSAE, preservation, and escalation contacts are safety@secretmsg.net , abuse@secretmsg.net , and legal@secretmsg.net . For possible CSAM, use the NCMEC CyberTipline directly.',
    ]),
    StaticSection('07 Applicable Child-Protection Commitments', [
      'SecretMsg applies COPPA, 18 U.S.C. § 2258A, and applicable regional child-protection, privacy, preservation, and emergency-disclosure requirements to the extent required by law.',
    ]),
    StaticSection('08 Contact Us & Reporting Concerns', [
      'A child, parent, guardian, or other concerned person may email safety@secretmsg.net without creating an account. For possible CSAM, report directly to the NCMEC CyberTipline. This policy is published at secretmsg.net/p/child-safety-policy .',
    ]),
  ]),
  'community-guidelines': StaticPageContent('Our Community Guidelines', [
    StaticSection('Overview', [
      'SecretMsg is the place to play Q&A games with your followers, connect with real-world friends, ask fun questions, reply in public or private, and be your fullest, most authentic self. To keep this community vibrant and safe, we have set up these essential guidelines.',
      'Provide accurate handle information. Authenticity creates trust. Dishonest registration violates our Terms of Service.',
      'Own your unique voice. We never ask for external social media passwords; your accounts and security are always protected.',
      'Strengthen friendships with curiosity and kindness. Remember: your fun should never come at the expense of someone else\'s peace of mind.',
    ]),
    StaticSection('Spam, Trolling, Misinformation & Promotion', [
      'Don’t submit repetitive messages, run automated bots, or flood a user\'s inbox with copy-pasted nonsense.',
      'Don’t use SecretMsg solely to instigate conflict, bait hostile arguments, or embarrass other people.',
      'Don’t impersonate other persons, spread knowingly fraudulent rumors, or interfere with civic or election processes.',
      'Don’t post pyramid schemes, chain letters, commercial ads, or claim false partnerships or endorsements with SecretMsg.',
    ]),
    StaticSection('What If You See Someone Violate These Guidelines? ⚠️', [
      'SecretMsg uses Turnstile verification and recipient-configured hidden-word filters, but it does not use machine-learning content classification and no safeguard is complete. Here is how you can act:',
      'Tap the Report icon (⚠), provide a reason, and complete Turnstile verification. Reporting stores the report and quarantines the message for review.',
      'Use the separate block action to store the app-generated sender-fingerprint hash in your block list and prevent that sender from sending to your link. This does not reveal the sender or create a network-wide IP block.',
      'Visit our Resources page for free, confidential mental health and anti-bullying hotlines.',
      'Messages that violate these Community Guidelines may be removed, and accounts may be restricted or terminated. Relevant criminal activity may be referred to appropriate authorities, but in-app reports are not automatically classified or submitted to law enforcement.',
    ]),
    StaticSection('The SecretMsg Golden Rule', [
      'SecretMsg is meant to be a fun, creative, and safe bridge between friends. Always be respectful, protect each other, and treat others the way you wish to be treated.',
    ]),
  ]),
  'contact': StaticPageContent('Contact Us', [
    StaticSection('Overview', [
      'Have questions, feedback, or need urgent trust & safety assistance? Reach out to our dedicated channels below.',
    ]),
    StaticSection('Trust, Abuse & Harassment', [
      'For cyberbullying, harassment, threats, or safety concerns.',
    ]),
    StaticSection('Child Protection & Minor Safety', [
      'Reports regarding an under-13 user, possible CSAE, or any child-endangerment concern.',
    ]),
    StaticSection('Privacy & GDPR Data Requests', [
      'Questions about privacy, account data, processor disclosures, or data-verification inquiries.',
    ]),
    StaticSection('Legal, DMCA & Law Enforcement', [
      'Official court orders, DMCA copyright takedown notices, or regulatory inquiries.',
    ]),
    StaticSection('General Inquiries & Feedback', [
      'Maintained by the SecretMsg Team .',
    ]),
  ]),
  'cookies': StaticPageContent('Cookies & Local Storage Policy', [
    StaticSection('Overview', [
      'SecretMsg is engineered without invasive trackers. We believe your online activity across other websites is none of our business.',
    ]),
    StaticSection('verified No Cookie Banners Needed — Here\'s Why', [
      'Under the EU ePrivacy Directive and GDPR guidelines, websites that utilize only strictly necessary, non-tracking cookies or local storage do not require intrusive, annoying consent banners. We only store the absolute minimum data required to keep the site functioning and defend against bots.',
    ]),
    StaticSection('01 What Are Cookies and Local Storage?', [
      'Cookies are small text files placed on your device (computer, smartphone, or tablet) when you visit a website. They are commonly used to make websites work efficiently, remember your preferences, and maintain secure sessions. Local storage technologies (like HTML5 local storage) provide cookie-equivalent functionality directly within your browser, allowing fast, client-side persistence of your settings without transmitting unnecessary data on every network request.',
    ]),
    StaticSection('02 How We Use Cookies & Local Storage', [
      'Stores whether you selected Dark Mode, Light Mode, or System Mode and your current active board identifier so the application renders in your preferred aesthetic and loads your link instantly without flickering.',
      'Temporary security token used to verify that you are a real person and not an automated spam bot. Does not track your personal identity or activity across third-party websites.',
      'Only present when you register and log into your board to access your private inbox. Kept encrypted, strictly restricted to secretmsg.net, and permanently discarded upon logout or account deletion.',
    ]),
    StaticSection('03 What We NEVER Store or Use', [
      '🚫 Zero Advertising Cookies: We do not partner with ad exchanges, data brokers, or retargeting networks.',
      '🚫 Zero Cross-Site Tracking: We never fingerprint your hardware or monitor your browsing behavior outside of secretmsg.net.',
      '🚫 Zero Commercial Analytics: No third-party marketing company receives session replay recordings or clickstream heatmaps.',
    ]),
    StaticSection('04 Your Choices & Managing Browser Storage', [
      'You have full control over cookies and local storage. You can withdraw your consent, block, or clear cookies and site data at any time through your browser\'s settings (such as Chrome Settings → Privacy & Security → Clear Browsing Data). Note that because we only use strictly necessary data, disabling all local storage may prevent you from remaining logged into your inbox or passing automated bot verification.',
    ]),
    StaticSection('05 GDPR & International Compliance', [
      'This Cookie Policy complies with the General Data Protection Regulation (GDPR) and the EU ePrivacy Directive. Because we use strictly essential, non-tracking technologies for basic security and preferences, we do not require intrusive tracking consent banners while ensuring you have complete transparency and control. For questions, reach out to privacy@secretmsg.net .',
    ]),
  ]),
  'disclaimer': StaticPageContent('Disclaimer & Limitation of Liability', [
    StaticSection('Overview', [
      'Operational disclosures, warranty disclaimers, and user content limitations for SecretMsg ( secretmsg.net ).',
    ]),
    StaticSection('01 Non-Commercial Personal Project Status', [
      'SecretMsg is an independent, non-commercial open-source project engineered and maintained by the SecretMsg Team for creative, social, and educational purposes.',
    ]),
    StaticSection('02 "As-Is" & "As-Available" Warranty Exclusion', [
      'THE SERVICE, CONTENT, AND UNDERLYING SOFTWARE ARE PROVIDED ON AN "AS-IS" BASIS WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, OR UNINTERRUPTED ERROR-FREE OPERATION. WE DO NOT GUARANTEE 100% CONTINUOUS SERVICE AVAILABILITY OR PREVENTION OF OCCASIONAL SERVICE INTERRUPTIONS.',
    ]),
    StaticSection('03 User-Generated Content & Conduit Rule', [
      'SecretMsg facilitates message transmission between participants. It applies Turnstile verification, recipient-configured hidden-word filtering, quarantine, reporting, and recipient-specific blocking, but it does not verify or endorse anonymous claims and does not use machine-learning content classification. Each user is responsible for messages they transmit.',
    ]),
    StaticSection('04 DMCA & Copyright Takedown Procedure', [
      'If you believe material hosted on or accessible via SecretMsg infringes upon your copyright or intellectual property rights, submit a takedown request containing:',
    ]),
  ]),
  'faq': StaticPageContent('Platform Guide & Frequently Asked Questions', [
    StaticSection('Overview', [
      'Everything you need to know about creating your link, sending anonymous messages, managing your board, troubleshooting URLs, and SecretMsg privacy practices.',
    ]),
    StaticSection('How to Create Your Anonymous Message Link', [
      'Getting started takes less than a minute:',
      'Open secretmsg.net in your browser or the SecretMsg app.',
      'Choose a handle or accept the generated handle used for your public SecretMsg link.',
      'Set a 4–6 digit PIN and save the backup codes. A real email is optional for the legacy email-code path; the normal handle/PIN path stores only a synthetic <handle>@v2.secretmsg placeholder that is not a mailbox.',
      'Create your account, then share your unique link on Instagram Stories, WhatsApp, Facebook, X, or another channel.',
    ]),
    StaticSection('How to Send an Anonymous Message', [
      'Sending an anonymous message does not require an account:',
      'Open the SecretMsg link shared by the Account User.',
      'Type a text message within the service limit.',
      'Complete Turnstile verification and send. SecretMsg does not ask for your name, email address, social handle, or account.',
      'The mobile app may send a stable app-generated random value so the server can store only its SHA-256 hash for recipient-controlled blocking. It is not a hardware identifier, and the recipient cannot reverse the hash into an identity.',
    ]),
    StaticSection('Creative Ways to Use Anonymous Messages', [
      'Here are popular ways people use SecretMsg every day:',
      'Add your SecretMsg link to your story sticker and let followers send anonymous questions, hot takes, or compliments.',
      'Share your link on WhatsApp and discover what your contacts really think about you.',
      'Collect candid feedback after meetups, workshops, podcast episodes, or team events.',
      'Teachers, professors, and study leaders can let students ask candid questions without fear of peer social pressure.',
      'Ask your personal and professional network for candid constructive opinions.',
    ]),
    StaticSection('Manage Your Secret Msg Board', [
      'Once your board is created, you can manage messages, your handle and profile, safety filters, sender blocks, reports, pairing, purchases, and deletion from the authenticated account controls.',
    ]),
    StaticSection('Troubleshooting: Why Your Secret Msg URL Might Not Work', [
      'If your anonymous message link won\'t open or looks broken, try these simple fixes:',
      'Confirm the link is spelled correctly and that the Account User has not paused the link.',
      'If authentication is unavailable, sign in with your handle and PIN. The public read-only web pairing session cannot make changes or delete an account.',
      'A stale browser cache can sometimes affect the page. Clear the browser cache and reload the link.',
      'Copy the exact link from your SecretMsg board rather than typing it manually.',
    ]),
    StaticSection('Frequently Asked Questions', [
      'A SecretMsg link is tied to an Account User profile. Anyone with the link can submit a text message without creating an account. The Account User can read the received inbox.',
      'SecretMsg does not ask for a sender name, email address, social handle, or account. It may store a hash of an app-generated random sender value for recipient-controlled blocking. Cloudflare processes the raw connecting IP to serve requests, and D1 stores SHA-256-derived rate-limit keys rather than readable IP addresses. Turnstile receives the raw connecting IP when verification is requested.',
      'Sign in with your handle and 4–6 digit PIN. A legacy account may instead use a real email and six-digit login code delivered by Resend.',
      'Use the PIN-change control after verifying your current PIN. Backup codes support account recovery when the primary PIN is unavailable.',
      'Use Delete Account in the app or secretmsg.net/delete-account with a full signed-in session. Successful deletion removes the primary D1 account row, handle, profile, received messages, blocked-sender records, reports involving the account, pairing codes, purchases, linked donations, email-keyed one-time-code sessions, and identifiable account-derived rate-limit rows. It does not purge unmapped IP-keyed rate limits, user-exported or shared copies, provider records, or encrypted backups, and the server sequence is not transactional.',
      'No account, sign-up, name, email address, or social handle is required to send. The Account User cannot receive a sender name because none is requested.',
      'If a link or authenticated page does not load, verify the URL, paused-link status, and authentication. Browser storage settings can affect web sessions.',
      'A SecretMsg link can be shared through a bio, direct link, or story sticker. Publicly exported story stickers can be saved or shared outside SecretMsg and are not deleted if the Account User later deletes the account.',
      'Account creation and anonymous sending are available without supporter payment. Optional Google Play purchases and Polar web donations support development.',
      'Account Users can delete individual messages, change their PIN, use safety controls, or request account deletion. A recipient can report a message or separately block the app-generated sender-fingerprint hash for that link.',
      'Delete or report uncomfortable messages from the inbox. For serious threats, contact local authorities. Do not claim that individual senders can be identified: the service does not ask for their identity, but a recipient can block future submissions from a sender-fingerprint hash.',
    ]),
    StaticSection('Ready to Receive Candid Anonymous Messages?', [
      'Create your SecretMsg link, save your recovery information, and review the privacy and child-safety policies before sharing it widely.',
    ]),
  ]),
  'online-safety-guide': StaticPageContent('Our Guide to Online Safety', [
    StaticSection('Overview', [
      'SecretMsg is built for authentic connections with friends. This guide describes implemented safety tools, reporting channels, and the limits of account deletion.',
      'Remove uncomfortable messages and use the separate block action when you do not want further submissions from that sender-fingerprint hash.',
      'Report concerning content in the app or email safety@secretmsg.net . Immediate danger should be reported to local emergency services.',
    ]),
    StaticSection('01 Staying Safe on SecretMsg', [
      'SecretMsg accepts text-only messages and uses Turnstile verification. These controls reduce abuse but do not make every message safe.',
      'Recipients can configure hidden-word filters. A standard-mode match is quarantined for review; a strict-mode match is rejected and quarantined. These rules-based controls do not use machine-learning content classification or understand context.',
      'See something, say something: report the message in the app with a reason, or email safety@secretmsg.net with the link and relevant details.',
    ]),
    StaticSection('02 What to Do If a Message Makes You Uncomfortable', [
      'If a message leaves you feeling uneasy or threatened, use the report and block controls as appropriate:',
      'Reporting stores the reason and pending or resolved status and quarantines the message. It does not automatically identify or globally block the sender.',
      'Blocking is separate. It stores the message\'s app-generated sender-fingerprint hash in that recipient\'s block list and removes the message. The raw app-generated value is not stored by SecretMsg, and the block is specific to the recipient\'s link.',
      'Visit our Resources page for free, confidential mental health and anti-bullying hotlines available 24/7.',
    ]),
    StaticSection('03 Practical Tips for Staying Safe & Protecting Privacy', [
      'Never share your home address, phone number, school location, or private contact details in public prompt cards or replies.',
      'Pause and consider whether you are comfortable with everyone seeing what you publish to social media or your public board.',
      'Remember there is a real human being reading your message. Keep the energy respectful and avoid threats, harassment, or sexual exploitation.',
      'Use Safety Controls in Settings to pause your link, configure hidden-word filters, or request account deletion. Review the Privacy Policy for provider, backup, copied-content, and IP-keyed rate-limit deletion limits.',
    ]),
    StaticSection('04 SecretMsg Procedures for Law Enforcement & Information Requests', [
      'SecretMsg may preserve or disclose relevant records when required by valid legal process or applicable law. Requests may be directed to legal@secretmsg.net with the official process and required case information.',
      'The current application code does not implement a dedicated law-enforcement request intake, automatic out-of-state-process acceptance, or fixed 180-day preservation workflow. This policy therefore does not promise those capabilities. Emergency disclosures and preservation remain subject to applicable law and verification through the designated legal channel.',
      'In-app reports are stored for operator review and are not automatically classified, escalated, or submitted to law enforcement.',
    ]),
  ]),
  'privacy': StaticPageContent('Privacy Policy', [
    StaticSection('Overview', [
      'At SecretMsg ( secretmsg.net ), privacy is not an afterthought or marketing slogan—it is the foundational design constraint of our entire architecture.',
    ]),
    StaticSection('No Sender Identity', [
      'We do not ask senders for a name, email address, social handle, or account. The mobile app may use a stable app-generated random value for recipient-controlled blocking, but the server stores only its SHA-256 hash. It is not a hardware identifier and the recipient cannot reverse it into an identity.',
    ]),
    StaticSection('Zero Data Brokers', [
      'We never sell, trade, or monetize user data. No Facebook or Google advertising pixels exist on our platform.',
    ]),
    StaticSection('Account Deletion', [
      'A successful account-deletion request removes the primary D1 account row, handle, profile, and received messages. It is not universal erasure; the processor, backup, local-copy, and rate-limit limits below apply.',
    ]),
    StaticSection('01 The Basics: How SecretMsg Works', [
      'SecretMsg allows users to receive questions and messages through social media and direct links. Senders submit without an account. Recipients can reply through a secure one-time link or publish an answer elsewhere. If both parties permit it, only a broad platform type such as Mobile / Android may be shown; SecretMsg does not provide precise location through this feature.',
    ]),
    StaticSection('02 Personal Information We Collect', [
      'The primary sign-in method is a handle and 4–6 digit PIN. An account may contain a random account ID, display name, avatar selection, bio, safety settings, hashed credentials, and an optional FCM registration token. Handle/PIN accounts store the synthetic placeholder <handle>@v2.secretmsg; it is not a mailbox. A real email is optional and is used only with the legacy email-code path.',
      'Message data includes text, replies, recipient settings, timestamps, delivery metadata, and report reasons. Cloudflare processes the raw connecting IP and request data to serve the service. Turnstile receives its challenge response and the raw connecting IP when verification is requested. No precise location is collected through SecretMsg.',
      'D1 stores SHA-256-derived rate-limit keys based on an IP address, handle, email address, or account ID as applicable. Raw IP addresses are not stored in readable form in the D1 rate-limit table, but Cloudflare processes the raw IP to serve the request and Turnstile receives it when verification is requested.',
      'The identifiers disclosed here are account IDs, optional FCM tokens, hashes of app-generated random sender values, and hashed rate-limit keys. None is a hardware ID or advertising ID. SecretMsg has no advertising, marketing, or analytics SDK.',
      'For a new message, FCM receives the registered token, a random message ID, the unread count, and a preview truncated to 140 characters, plus an ellipsis when truncated. The full message body is not sent through FCM.',
    ]),
    StaticSection('03 What We Will NEVER Do', [
      'We never sell, rent, license, or monetize personal information, messages, or emails to advertisers or third-party data brokers.',
      'We never disclose a sender\'s name or account to the recipient because we do not ask for one.',
      'We never use advertising pixels, retargeting, cross-site behavioral advertising, Firebase Analytics, Crashlytics, or another advertising or analytics SDK.',
    ]),
    StaticSection('05 Automated Safety & Content Moderation', [
      'Message submission and reporting use Cloudflare Turnstile. Recipient-configured hidden-word matching quarantines a match in standard mode and rejects and quarantines it in strict mode. These are rules-based safeguards, not machine-learning content classification, and they do not understand context or reliably identify CSAE, grooming, or other abuse.',
      'Reporting records a reason and quarantines the message. Blocking is separate: it stores the app-generated sender-fingerprint hash in that recipient\'s block list and removes the message. Reporting and blocking do not reveal the sender\'s identity.',
    ]),
    StaticSection('06 How Information Is Shared', [
      'When an Account User publishes a response, the question and answer become visible on the chosen public thread or elsewhere. We also use the following service processors:',
      'Cloudflare: hosts the API, processes request content, headers, and the raw connecting IP, stores primary records in D1, handles Turnstile verification with the challenge response and raw connecting IP, and may receive encrypted D1 backups in R2.',
      'Resend: receives a real email address and six-digit login code only for the legacy email-code path. The handle/PIN path uses a synthetic placeholder and does not send a login email.',
      'Google Play Billing: receives the purchase token and product ID for verification. SecretMsg receives purchase state and an order ID when available, but never receives or stores card details.',
      'Google Firebase Cloud Messaging: receives the FCM token, random message ID, unread count, and 140-character truncated preview. It does not receive the full message body.',
      'Polar: the current web donation link does not append a SecretMsg username or email. Checkout information is provided directly to Polar, which may return a verified webhook with donor information, amount, and donation metadata. SecretMsg may use a public name or email local part as the supporter alias and supplied account metadata to link eligible perks.',
      'We may disclose relevant information to comply with valid legal process, prevent imminent harm, enforce our terms, protect users, or preserve relevant records.',
    ]),
    StaticSection('07 Your Rights & Choices (GDPR & CCPA)', [
      'Depending on your location, you may have rights to access, correct, export, restrict, object to, or request deletion of personal information. Profile and safety fields can be updated directly; contact privacy@secretmsg.net for other requests.',
      'Open Settings → Delete Account or use the public Delete Account page at secretmsg.net/delete-account with a full signed-in session. A successful request deletes received messages, blocked-sender records, reports involving the account as recipient or reporter, pairing codes, purchase records, linked donations, email-keyed one-time-code sessions, identifiable account-derived rate-limit rows, and the primary D1 account row.',
      'For a handle/PIN account, account-row deletion removes the synthetic <handle>@v2.secretmsg placeholder; no deletion message is sent because it is not a mailbox. For a legacy account, the real email is removed from D1, but provider-side copies are outside this operation.',
      'Deletion limits: IP-keyed rate-limit rows that cannot be mapped to the account are not explicitly purged; copies you exported, saved, posted, or shared cannot be retracted; records held independently by Google, Resend, Polar, Cloudflare, or other providers are not erased by this endpoint; encrypted R2 backups have no verified post-deletion purge; and the server deletion steps are sequential rather than transactional, so a failed request can leave partial deletion until retried or support assists.',
      'The mobile app attempts to clear local account data after the server request, but local cleanup is separate from the server transaction. The account cannot be restored after successful deletion.',
    ]),
    StaticSection('08 Do Not Track Signals', [
      'Because we do not track users across third-party websites for advertising or serve targeted behavioral advertising, our privacy practices remain consistent whether or not a browser transmits a Do Not Track signal.',
    ]),
    StaticSection('09 Children\'s Privacy', [
      'SecretMsg is not directed to children under 13, or to a higher minimum age where local law requires it. Users aged 13–17 may use the service only with parent or legal-guardian permission. Parents or guardians may contact safety@secretmsg.net to request review and deletion of information submitted by an under-13 user. The child-safety policy is published at secretmsg.net/p/child-safety-policy .',
    ]),
    StaticSection('10 Data Retention & Security Practices', [
      'Pairing codes are usable for approximately 5 minutes. Expired rows are removed by the next scheduled cleanup; consumed rows remain for at least 24 hours and are removed by the first scheduled cleanup after that threshold.',
      'Legacy email login codes are valid for 15 minutes. Their hashed rows are rejected after expiry and removed by the next scheduled cleanup, not necessarily at the exact expiry second.',
      'Rate-limit counters stop counting after their applicable 1-minute to 1-hour window. Rows whose window began more than 2 hours earlier are removed by nightly cleanup.',
      'Messages remain until the recipient deletes them or the Account User deletes the account. Reports remain pending or resolved in D1 until account deletion; separate legal-preservation requirements may apply. Account records remain while active; FCM tokens remain until unregister, stale-token clearing, or account deletion.',
      'Processor and legal-preservation periods are controlled independently and may be longer. SecretMsg uses HTTPS for implemented application and processor paths along with authentication, hashed credentials, rate limits, and other technical and administrative safeguards.',
    ]),
    StaticSection('11 Inquiries & Data Protection Contact', [
      'If you have questions regarding this Privacy Policy, our data practices, or wish to exercise a legal privacy right, contact privacy@secretmsg.net or support@secretmsg.net .',
    ]),
  ]),
  'safety': StaticPageContent('Safety Center & Crisis Help', [
    StaticSection('Overview', [
      'Your emotional well-being and psychological safety are paramount. Discover our recipient-configured safeguards, reporting procedures, and immediate 24/7 crisis hotlines.',
      'If you or someone you know is feeling overwhelmed, hopeless, or experiencing suicidal thoughts, free confidential support is available 24/7:',
    ]),
    StaticSection('policy Explore Safety & Community Policies', [
      'Zero tolerance for CSAE, no targeting of children under 13, parent or guardian permission for ages 13–17, and an NCMEC CyberTipline escalation path when required.',
      'Turnstile verification, recipient-configured hidden-word quarantine, reporting, and recipient-specific sender blocking. The service does not use machine-learning content classification or claim a staffed 24-hour review team.',
      'Actionable digital wellness practices, anti-cyberbullying strategies, social media boundaries, and healthy communication etiquette.',
      'Clear rules of conduct, prohibited behavior, harassment prevention, and possible account or message actions.',
      'In-app reporting, double-blind replies, individual message deletion, and account deletion with disclosed limits.',
      '24/7 confidential crisis hotlines, 988 Suicide & Crisis Lifeline, Crisis Text Line 741741, Trevor Project, and global directories.',
      'Child-safety, abuse, legal, privacy, and support contact channels.',
    ]),
    StaticSection('tips_and_updates Advice for Teens & Parents', [
      '💡 Remember that feedback does not define you: Anonymous messages reflect the sender\'s thoughts, not your worth. If a message ever feels uncomfortable, delete or report it immediately.',
      '💡 Never share sensitive personal info: Never post your home address, phone number, school location, or private credentials in your public link or reply stickers.',
      '💡 Take breaks when needed: If social media or feedback starts feeling stressful, pause or delete your link. You have 100% control.',
    ]),
    StaticSection('report Urgent Abuse Assistance', [
      'If you encounter cyberbullying or illegal activity, report it directly to our moderation queue:',
    ]),
  ]),
  'safety-resources': StaticPageContent('Our Safety & Wellbeing Resources', [
    StaticSection('Overview', [
      'If you or someone you know is going through emotional turmoil, experiencing bullying, feeling unsafe, or needing support, you are never alone. Reach out to these free, confidential organizations supporting our global community.',
      'If you or someone else is in imminent physical danger, please call your local emergency services (e.g. 911 in the US/Canada, 999 in the UK, 112 in Europe, 000 in Australia) immediately.',
    ]),
  ]),
  'safety-tools': StaticPageContent('Our Safety Tools & Controls', [
    StaticSection('Overview', [
      'SecretMsg puts complete sovereignty over your inbox directly into your hands. Every account holder has access to real-time proactive safety controls designed to prevent abuse, enforce digital boundaries, and filter unwanted language down to specific emojis.',
    ]),
    StaticSection('Pause Submissions (Quiet Mode)', [
      'If you ever feel overwhelmed, need to study, or want to take a break from social media, you can freeze your SecretMsg link instantly. When your link is paused, no one can send you messages.',
    ]),
    StaticSection('Filtered Words, Phrases & Emojis', [
      'Create a personalized hidden-word list tailored to your boundaries, including specific keywords, phrases, or emoji text.',
      'In standard mode, a matching message is stored in a separate quarantine tray and does not appear in the main inbox. In strict mode, the sender is rejected and the message is still quarantined for your review.',
      'The hidden-word filter is deterministic and recipient-configured. It is not machine-learning content classification and may not identify abuse that does not match a configured term.',
    ]),
    StaticSection('App-Generated Sender Blocking', [
      'If someone sends you a message that violates your boundaries, you can prevent future submissions from that mobile-app installation without knowing the sender\'s identity.',
      'Use the separate block action on the message. It stores only the SHA-256 hash of the app-generated random sender value in your block list and removes the message.',
      'The app-generated value is not a hardware identifier, and the block is specific to your link. It does not create a network-wide IP block or reveal the sender to you.',
      'Review and unblock sender-fingerprint hashes in Settings.',
    ]),
    StaticSection('01 What, Who & When: Complete Recipient Sovereignty', [
      'Together, these tools ensure that you—and only you—control the experience on your link:',
    ]),
    StaticSection('02 Account Deletion & Its Limits', [
      'You can delete individual inbox messages at any time. The server endpoint also removes the account row, handle, profile, received messages, blocked-sender records, reports involving the account, pairing codes, purchases, linked donations, email-keyed one-time-code sessions, and identifiable account-derived rate-limit rows.',
      'Self-service deletion is available from Settings or secretmsg.net/delete-account with a full signed-in session. The server sequence is not transactional. It does not purge unmapped IP-keyed rate limits, copies you exported or shared, independent provider records, or encrypted backups with no verified post-deletion purge.',
    ]),
    StaticSection('03 Safety Contacts & 24/7 Crisis Assistance', [
      'For harassment, threats, or child-safety concerns, report in the app or email safety@secretmsg.net . SecretMsg does not claim a staffed 24-hour review team. Separate third-party crisis lifelines may be available 24/7, and immediate danger should be reported to local emergency services.',
    ]),
    StaticSection('Safety Contacts', [
      'Contact safety@secretmsg.net , abuse@secretmsg.net , privacy@secretmsg.net , or support@secretmsg.net as appropriate.',
    ]),
    StaticSection('Crisis & Mental Health Hotlines', [
      'Free, confidential, and available 24 hours a day, 7 days a week:',
    ]),
    StaticSection('Ready to customize your safety preferences?', [
      'Configure your filtered words, pause your link, or adjust notification alerts in Settings.',
    ]),
  ]),
  'terms': StaticPageContent('Terms of Service', [
    StaticSection('Overview', [
      'Please read these Terms of Service carefully before utilizing SecretMsg ( secretmsg.net ). By accessing our services, you agree to be bound by this agreement.',
    ]),
    StaticSection('Strict Anti-Harassment & Zero Tolerance Policy', [
      'SecretMsg prohibits hate speech, cyberbullying, sexual harassment, threats of self-harm, extortion, CSAE, and other illegal conduct. Depending on evidence and applicable law, violations may result in message or account action, recipient-specific sender blocking, record preservation, and referral to appropriate authorities. The service does not claim an automated network-wide IP block or automatic law-enforcement referral.',
    ]),
    StaticSection('01 Interpretation & Definitions', [
      'The words with capitalized initial letters have meanings defined under the following conditions. The following definitions have the same meaning regardless of whether they appear in singular or in plural:',
    ]),
    StaticSection('02 Acknowledgment & Eligibility', [
      'These Terms and Conditions govern the use of this Service and form the binding agreement between You and the Company. They set out the rights and obligations of all visitors, users, and others who access or use SecretMsg.',
      'By accessing or using the Service, You agree to be bound by these Terms. If You disagree with any part of these Terms, You may not access the Service.',
      'Age Requirement: You represent that You are at least 18 years of age, or if You are between 13 and 17, that You possess the consent of a parent or legal guardian to access and use the Service in compliance with applicable law. The Service is not intended for or directed to individuals under 13 years of age.',
      'Your access to and use of the Service is also conditioned on Your acceptance of and compliance with our Privacy Policy and Cookies Policy .',
    ]),
    StaticSection('03 User Accounts & Handle Guidelines', [
      'When You create an account with Us, You must provide accurate, complete, and current information. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of Your account.',
      'You are responsible for safeguarding your PIN and backup codes. You agree not to disclose them to any third party and must notify SecretMsg promptly if you believe an account has been accessed without authorization.',
      'Handle & Username Restrictions: You may not use as a username or URL slug the name of another person or entity with the intent to impersonate them, a name or trademark subject to any third-party rights without proper authorization, or a name that is offensive, vulgar, or obscene. We reserve the right to reclaim, suspend, or reassign usernames at our sole discretion.',
    ]),
    StaticSection('04 Content: Rights, Licenses & Public Replies', [
      'Your Right to Post: Our Service allows You to receive anonymous messages and post responses. You are solely responsible for the Content You post, including its legality, reliability, and appropriateness.',
      'License Granted to SecretMsg: By posting Content to the Service (including public replies, questions, or shared thread answers), You grant Us a non-exclusive, worldwide, royalty-free license to use, reproduce, modify, publicly display, and distribute such Content on and through the Service solely for operating, promoting, and improving the platform. You retain all Your ownership rights in Your Content.',
      'Public Q&A & Social Stickers: You understand that when You choose to mark an answer as public or export a Q&A card to social media, that Content becomes publicly accessible. You represent and warrant that the posting of Your Content does not violate the intellectual property, privacy, or publicity rights of any third party.',
    ]),
    StaticSection('05 Content Restrictions & Acceptable Use', [
      'The Company is not responsible for the content posted by users or anonymous senders. You expressly agree that You will not post, upload, transmit, or distribute any Content that is:',
      'The Company reserves the right, but not the obligation, to determine whether Content complies with these Terms, and to format, edit, refuse, or remove Content at any time. As SecretMsg facilitates anonymous feedback, You agree to use the Service at Your own risk.',
    ]),
    StaticSection('06 Content Backups', [
      'The operator may create encrypted D1 backups, including copies uploaded to Cloudflare R2. The current code does not establish that every deletion is purged from a backup. You are encouraged to maintain independent copies of important Content.',
    ]),
    StaticSection('07 Copyright Policy & DMCA Takedown Procedure', [
      'We respect the intellectual property rights of others. If You believe that Content on the Service infringes Your copyright, You may submit a written notice to our designated Copyright Agent at legal@secretmsg.net pursuant to the Digital Millennium Copyright Act (DMCA) (17 U.S.C. § 512(c)(3)) with the following:',
    ]),
    StaticSection('08 Feedback Provided by You', [
      'You assign all rights, title, and interest in any Feedback You provide to the Company. If such assignment is ineffective, You grant the Company an exclusive, perpetual, irrevocable, royalty-free, worldwide license to use, reproduce, disclose, sub-license, distribute, and exploit such Feedback without restriction or compensation.',
    ]),
    StaticSection('09 In-App Purchases, Billing & Subscriptions', [
      'The Service may offer optional In-App Purchases, virtual items, or supporter badges. All billing and transaction processing are handled by authorized payment processors or application stores.',
      'In-App Purchases are consumed within the Service and cannot be cancelled or redeemed for cash once initiated. If an item fails to deliver due to technical error, contact us at support@secretmsg.net for investigation and prompt resolution or refund authorization.',
    ]),
    StaticSection('10 Links to Other Websites & Third-Party Platforms', [
      'Our Service may contain links to third-party websites or services that are not owned or controlled by the Company (including Instagram, WhatsApp, TikTok, and X). We assume no responsibility for the content, privacy policies, or practices of any third-party websites. You acknowledge that the Company shall not be liable for any damage or loss caused by reliance on external services.',
    ]),
    StaticSection('11 Termination & Account Deletion', [
      'We may suspend or terminate an account for a Terms violation or as otherwise permitted by these Terms. You may request account deletion through Settings or secretmsg.net/delete-account with a full signed-in session. A successful request removes the primary D1 account row, handle, profile, received messages, and other listed account-linked records. It does not purge unmapped IP-keyed rate limits, user-exported or shared copies, provider records, or encrypted backups. The server deletion sequence is not transactional and cannot be reversed.',
    ]),
    StaticSection('12 Limitation of Liability', [
      'Notwithstanding any damages that You might incur, the entire liability of the Company and any of its suppliers under any provision of these Terms, and Your exclusive remedy for all of the foregoing, shall be limited to the amount actually paid by You through the Service, or 100 USD if You have not purchased anything through the Service.',
      'To the maximum extent permitted by applicable law, in no event shall the Company or its suppliers be liable for any special, incidental, indirect, or consequential damages whatsoever (including loss of profits, loss of data, business interruption, personal injury, or loss of privacy) arising out of or related to the use of or inability to use the Service.',
    ]),
    StaticSection('13 "AS IS" and "AS AVAILABLE" Disclaimer', [
      'The Service is provided to You "AS IS" AND "AS AVAILABLE" with all faults and defects without warranty of any kind. To the maximum extent permitted under applicable law, the Company expressly disclaims all warranties, whether express, implied, statutory, or otherwise, including merchantability, fitness for a particular purpose, title, non-infringement, and warranties arising out of course of dealing or usage. We make no warranty that the Service will meet Your requirements, operate uninterrupted, or be error-free.',
    ]),
    StaticSection('14 Governing Law, Disputes & Jurisdiction', [
      'The laws of the State of California, United States, excluding conflicts of law rules, shall govern these Terms and Your use of the Service.',
      'Informal Resolution: If You have any concern or dispute about the Service, You agree to first attempt to resolve the dispute informally by contacting the Company at support@secretmsg.net .',
      'For European Union (EU) Users: If You are an EU consumer, You benefit from any mandatory provisions of the law of the country in which You reside.',
      'United States Legal Compliance: You represent and warrant that (i) You are not located in a country subject to U.S. government embargo, or designated as a "terrorist supporting" country, and (ii) You are not listed on any U.S. government list of prohibited or restricted parties.',
    ]),
    StaticSection('15 Severability, Waiver & Changes to Terms', [
      'Severability & Waiver: If any provision of these Terms is held to be invalid or unenforceable, such provision will be interpreted to accomplish its objectives to the greatest extent possible, and remaining provisions continue in full force. Failure to exercise a right does not waive future enforcement.',
      'Changes to These Terms: We reserve the right to modify or replace these Terms at any time. If a revision is material, We will make reasonable efforts to provide at least 30 days\' notice prior to new terms taking effect. By continuing to use the Service after revisions become effective, You agree to be bound by the revised terms.',
    ]),
    StaticSection('16 Contact Information', [
      'If You have questions about these Terms and Conditions or wish to report violations, reach out to our team:',
    ]),
  ]),
};