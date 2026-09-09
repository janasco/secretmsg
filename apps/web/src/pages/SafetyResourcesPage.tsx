import React from 'react';
import { Phone, Mail, AlertTriangle } from 'lucide-react';
import { PublicPage } from '../components/PublicPage';

interface Resource {
  name: string;
  phone?: string;
  phoneLink?: string;
  description: string;
}

interface CountryResources {
  country: string;
  flag: string;
  resources: Resource[];
}

const crisisResources: CountryResources[] = [
  {
    country: 'Argentina',
    flag: '\u{1F1E6}\u{1F1F7}',
    resources: [
      { name: 'Centro de Asistencia al Suicida', description: 'Suicide prevention & crisis emotional support' },
      { name: 'Chicos.net', description: 'Online safety, digital literacy & youth guidance' },
    ],
  },
  {
    country: 'Australia',
    flag: '\u{1F1E6}\u{1F1FA}',
    resources: [
      { name: 'Lifeline', phone: 'Call 13 11 14', phoneLink: 'tel:131114', description: '24/7 crisis support & suicide prevention' },
      { name: 'Beyond Blue', description: 'Mental health, anxiety & depression support' },
      { name: 'eSafety Commissioner', description: 'Bullying, online safety, privacy & image abuse' },
      { name: 'Bullying No Way', description: 'Anti-bullying school & peer resources' },
      { name: 'Headspace', description: 'National youth mental health foundation' },
      { name: 'QLife', description: 'Anonymous LGBTQIA+ peer support and referral' },
      { name: 'ReachOut', description: 'Youth mental health, bullying & identity support' },
    ],
  },
  {
    country: 'Austria',
    flag: '\u{1F1E6}\u{1F1F9}',
    resources: [
      { name: 'Rat auf Draht', phone: 'Dial 147', description: 'Online safety, relationships, sexuality & crisis' },
      { name: 'Saferinternet.at', description: 'Digital protection, privacy & internet wellbeing' },
      { name: 'TelefonSeelsorge', phone: 'Dial 142', description: '24/7 mental health & suicide prevention' },
    ],
  },
  {
    country: 'Belgium',
    flag: '\u{1F1E7}\u{1F1EA}',
    resources: [
      { name: 'Zelfmoord 1813', phone: 'Dial 1813', description: '24/7 suicide prevention helpline & chat' },
    ],
  },
  {
    country: 'Brazil',
    flag: '\u{1F1E7}\u{1F1F7}',
    resources: [
      { name: 'Como Vai Voc\u00ea (CVV)', phone: 'Dial 188', description: 'Emotional support & suicide prevention' },
      { name: 'SaferNet Brasil', description: 'Human rights online & cyberbullying reporting helpline' },
    ],
  },
  {
    country: 'Canada',
    flag: '\u{1F1E8}\u{1F1E6}',
    resources: [
      { name: 'Canada Suicide Crisis Helpline (988)', phone: 'Call or text 988', phoneLink: 'tel:988', description: '24/7 bilingual crisis line' },
      { name: 'Crisis Text Line Canada', phone: 'Text 686868', description: 'Free 24/7 youth crisis chat' },
      { name: 'Cybertip.ca', description: 'National tip line against child sexual exploitation' },
      { name: 'Get Cyber Safe', description: 'Government of Canada national cybersecurity initiative' },
      { name: 'mindyourmind', description: 'Youth mental health education & tools' },
      { name: 'Amelia Rising Sexual Violence Support', description: 'Crisis support for sexual violence survivors' },
    ],
  },
  {
    country: 'Chile',
    flag: '\u{1F1E8}\u{1F1F1}',
    resources: [
      { name: 'L\u00ednea Libre', description: 'Mental health & psychological support for kids and teens' },
      { name: 'Todo Mejora', description: 'Bullying prevention & LGBTQ+ youth support' },
    ],
  },
  {
    country: 'Colombia',
    flag: '\u{1F1E8}\u{1F1F4}',
    resources: [
      { name: 'L\u00ednea 106', description: 'Free psychological help & crisis listening' },
      { name: 'Fundaci\u00f3n Sergio Urrego', description: 'Anti-discrimination & youth suicide prevention' },
      { name: 'Te Protejo', description: 'Reporting online child exploitation & cyberbullying' },
    ],
  },
  {
    country: 'Denmark',
    flag: '\u{1F1E9}\u{1F1F0}',
    resources: [
      { name: 'B\u00f8rneTelefonen', phone: 'Dial 116 111', phoneLink: 'tel:116111', description: 'Child & youth advice on bullying and mental health' },
      { name: 'Livslinien', phone: 'Call 70 201 201', phoneLink: 'tel:70201201', description: 'Suicide prevention helpline' },
      { name: 'Medier\u00e5det for B\u00f8rn og Unge', description: 'National media & internet safety council' },
      { name: 'Red Barnet (Save the Children)', description: 'Anti-bullying & digital child protection' },
    ],
  },
  {
    country: 'Finland',
    flag: '\u{1F1EB}\u{1F1EE}',
    resources: [
      { name: 'Nuorten-netti (MLL)', description: 'Youth online safety, peer support & crisis chat' },
      { name: 'Mieli ry (Mental Health Finland)', description: '24/7 crisis helpline for mental health' },
    ],
  },
  {
    country: 'France',
    flag: '\u{1F1EB}\u{1F1F7}',
    resources: [
      { name: 'Net \u00c9coute (3018)', description: 'National toll-free number against cyberbullying & digital violence' },
      { name: 'Suicide \u00c9coute', description: '24/7 suicide prevention listening service' },
      { name: 'Internet Sans Crainte', description: 'National safer internet program for youth' },
      { name: 'Le Refuge', description: 'Emergency support & shelter for LGBTQ+ youth' },
      { name: 'Point de Contact', description: 'Reporting illicit and harmful online content' },
    ],
  },
  {
    country: 'Germany',
    flag: '\u{1F1E9}\u{1F1EA}',
    resources: [
      { name: 'Nummer gegen Kummer', phone: 'Dial 116 111', phoneLink: 'tel:116111', description: 'Helpline for kids, teens, and parents' },
      { name: 'Klicksafe.de', description: 'EU internet initiative promoting media safety' },
      { name: 'TelefonSeelsorge', description: '24/7 free emotional & suicide prevention hotline' },
    ],
  },
  {
    country: 'Hungary',
    flag: '\u{1F1ED}\u{1F1FA}',
    resources: [
      { name: 'K\u00e9k Vonal', phone: 'Dial 116 111', phoneLink: 'tel:116111', description: 'Child crisis foundation' },
      { name: 'Saferinternet.hu', description: 'Digital education & online safety hotline' },
    ],
  },
  {
    country: 'India',
    flag: '\u{1F1EE}\u{1F1F3}',
    resources: [
      { name: 'AASRA', description: '24/7 suicide prevention & mental health helpline' },
      { name: 'DISC Foundation', description: 'Cyber safety, digital citizenship & internet ethics' },
      { name: 'SNEHA India', description: 'Suicide prevention & emotional health services' },
    ],
  },
  {
    country: 'Ireland',
    flag: '\u{1F1EE}\u{1F1EA}',
    resources: [
      { name: 'Pieta House', description: 'Suicide & self-harm crisis helpline' },
      { name: 'Samaritans Ireland', phone: 'Call 116 123', phoneLink: 'tel:116123', description: '24/7 free confidential listening' },
      { name: 'Crisis Text Line Ireland', phone: 'Text 50808', description: '24/7 free text support' },
      { name: 'Webwise.ie', description: 'Irish safer internet centre & cyber safety guides' },
      { name: 'Belong To Youth Services', description: 'Supporting LGBTQ+ young people' },
      { name: 'Jigsaw', description: 'Youth mental health advice and mental fitness' },
      { name: 'SpunOut', description: 'Youth information platform for wellbeing & mental health' },
      { name: 'Turn2Me', description: 'Online mental health counseling & support groups' },
    ],
  },
  {
    country: 'Italy',
    flag: '\u{1F1EE}\u{1F1F9}',
    resources: [
      { name: 'Telefono Azzurro', phone: 'Dial 19696', description: 'Child protection & anti-bullying hotline' },
      { name: 'Generazioni Connesse', description: 'Safer Internet Centre for Italy' },
      { name: 'Telefono Amico Italia', description: 'Emotional support & crisis prevention' },
    ],
  },
  {
    country: 'Luxembourg',
    flag: '\u{1F1F1}\u{1F1FA}',
    resources: [
      { name: 'Kanner-Jugendtelefon (KJT)', phone: 'Dial 116 111', phoneLink: 'tel:116111', description: 'Youth listening & online safety hotline' },
      { name: 'BEE SECURE', description: 'National safer internet initiative' },
    ],
  },
  {
    country: 'The Netherlands',
    flag: '\u{1F1F3}\u{1F1F1}',
    resources: [
      { name: '113 Zelfmoordpreventie', phone: 'Dial 113', phoneLink: 'tel:113', description: 'National suicide prevention hotline' },
      { name: 'De Kindertelefoon', phone: 'Dial 0800-0432', phoneLink: 'tel:08000432', description: 'Free child & teen confidential hotline' },
      { name: 'MIND Korrelatie', description: 'Mental health support & anti-discrimination' },
      { name: 'Safer Internet Centre Netherlands', description: 'Digital wellness & cyber security education' },
    ],
  },
  {
    country: 'New Zealand',
    flag: '\u{1F1F3}\u{1F1FF}',
    resources: [
      { name: 'Lifeline Aotearoa', phone: 'Dial 0800 543 354', phoneLink: 'tel:0800543354', description: '24/7 helpline' },
      { name: 'Netsafe NZ', description: 'Independent online safety organisation' },
      { name: '0800 What\'s Up', description: 'Children and teens counseling helpline' },
      { name: 'The Lowdown', description: 'Depression and anxiety support for young Kiwis' },
      { name: 'Depression.org.nz', description: 'Mental health self-help & free support' },
      { name: 'Generation Online', description: 'Youth digital literacy & wellbeing' },
    ],
  },
  {
    country: 'Norway',
    flag: '\u{1F1F3}\u{1F1F4}',
    resources: [
      { name: 'Kirkens SOS', phone: 'Call 22 40 00 40', phoneLink: 'tel:22400040', description: '24/7 crisis line' },
      { name: 'Mental Helse Hjelpetelefonen', phone: 'Dial 116 123', phoneLink: 'tel:116123', description: 'Free 24/7 mental health hotline' },
      { name: 'Medietilsynet', description: 'Norwegian media authority & safe internet campaigns' },
    ],
  },
  {
    country: 'Spain',
    flag: '\u{1F1EA}\u{1F1F8}',
    resources: [
      { name: 'Tel\u00e9fono de la Esperanza', description: 'Crisis emotional listening & suicide prevention' },
      { name: 'IS4K (Internet Segura for Kids)', phone: 'Dial 017', phoneLink: 'tel:017', description: 'National safer internet centre' },
    ],
  },
  {
    country: 'Sweden',
    flag: '\u{1F1F8}\u{1F1EA}',
    resources: [
      { name: 'Mind.se', phone: 'Dial 90101', phoneLink: 'tel:90101', description: 'Suicide prevention & mental health support line' },
      { name: 'Safer Internet Centre Sweden', description: 'Digital rights & cyber protection' },
      { name: 'Jourhavande Medm\u00e4nniska', phone: 'Dial 08-702 16 80', phoneLink: 'tel:087021680', description: 'Nighttime emotional support' },
    ],
  },
  {
    country: 'United Kingdom',
    flag: '\u{1F1EC}\u{1F1E7}',
    resources: [
      { name: 'Samaritans UK', phone: 'Dial 116 123', phoneLink: 'tel:116123', description: '24/7 free emotional listening from any phone' },
      { name: 'Shout 85258', phone: 'Text SHOUT to 85258', description: 'Free, confidential 24/7 text support' },
      { name: 'Papyrus UK', phone: 'Call 0800 068 4141', phoneLink: 'tel:08000684141', description: 'Prevention of young suicide' },
      { name: 'Anti-Bullying Alliance & The Diana Award', description: 'National anti-bullying leadership and peer advocacy' },
      { name: 'CEOP & Thinkuknow', description: 'National Crime Agency child exploitation command' },
      { name: 'Internet Watch Foundation (IWF)', description: 'Removing illicit content & protecting children online' },
      { name: 'Switchboard LGBT+ Helpline', description: 'Confidential listening for the LGBT+ community' },
      { name: 'Revenge Porn Helpline', description: 'Support for victims of non-consensual intimate imagery' },
      { name: 'Ditch the Label', description: 'Youth mental health & anti-bullying community' },
      { name: 'The Mix', description: 'Essential support for under 25s across life challenges' },
    ],
  },
  {
    country: 'United States of America',
    flag: '\u{1F1FA}\u{1F1F8}',
    resources: [
      { name: '988 Suicide & Crisis Lifeline', phone: 'Call or text 988', phoneLink: 'tel:988', description: '24/7 free emotional support' },
      { name: 'Crisis Text Line', phone: 'Text HOME to 741741', description: '24/7 mental health counseling' },
      { name: 'The Trevor Project', phone: '1-866-488-7386', phoneLink: 'tel:18664887386', description: 'LGBTQ+ youth suicide prevention' },
      { name: 'Trans Lifeline', phone: '877-565-8860', phoneLink: 'tel:8775658860', description: 'Peer support by and for trans individuals' },
      { name: 'National Alliance on Mental Illness (NAMI)', phone: '1-800-950-6264', phoneLink: 'tel:18009506264', description: 'Mental health education & support helpline' },
      { name: 'Cyberbullying Research Center', description: 'Expert data, advice & cyberbullying prevention tools' },
      { name: 'ConnectSafely & FOSI', description: 'Family online safety & digital citizenship' },
      { name: 'Active Minds', description: 'Youth mental health advocacy & peer empowerment' },
      { name: 'Thatsnotcool', description: 'Healthy relationships & digital boundaries' },
      { name: 'Common Sense Media', description: 'Digital wellbeing, privacy & tech advice for families' },
    ],
  },
];

export const SafetyResourcesPage: React.FC = () => {
  return (
    <PublicPage
      title="Our Safety & Wellbeing Resources"
      description="If you or someone you know is going through emotional turmoil, experiencing bullying, feeling unsafe, or needing support, you are never alone. Reach out to these free, confidential organizations supporting our global community."
    >
      <div className="glass-panel rounded-2xl p-5 border border-rose-500/30 bg-rose-950/20 mb-10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-1 text-xs">
          <strong className="text-rose-300 text-sm font-bold flex items-center gap-1.5">
            <AlertTriangle className="w-4 h-4" />
            In Immediate Danger?
          </strong>
          <p className="text-slate-300 leading-relaxed">
            If you or someone else is in imminent physical danger, please call your local emergency services (e.g. 911 in the US/Canada, 999 in the UK, 112 in Europe, 000 in Australia) immediately.
          </p>
        </div>
        <a href="tel:988" className="px-5 py-2.5 bg-rose-500 hover:bg-rose-600 text-white rounded-full text-xs font-bold text-center shrink-0 transition-colors">
          Call 988 (US/CA)
        </a>
      </div>

      <div className="glass-panel rounded-2xl p-6 sm:p-8 border border-indigo-500/30 bg-indigo-950/20 mb-10 text-center space-y-4">
        <div className="w-14 h-14 rounded-2xl bg-indigo-500/20 text-indigo-400 flex items-center justify-center mx-auto">
          <Phone className="w-7 h-7" />
        </div>
        <h2 className="text-xl font-bold text-white">988 Suicide &amp; Crisis Lifeline</h2>
        <p className="text-slate-300 text-sm max-w-md mx-auto">
          Free, confidential 24/7 support for anyone in emotional distress or suicidal crisis. Call or text 988, or chat at 988lifeline.org.
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
          <a href="tel:988" className="px-6 py-3 rounded-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-sm transition-colors flex items-center gap-2">
            <Phone className="w-4 h-4" />
            Call 988
          </a>
          <a href="sms:988" className="px-6 py-3 rounded-full bg-white/10 hover:bg-white/20 text-white font-bold text-sm transition-colors flex items-center gap-2 border border-white/10">
            <Mail className="w-4 h-4" />
            Text 988
          </a>
        </div>
      </div>

      <div className="space-y-8">
        {crisisResources.map((country) => (
          <section key={country.country} className="glass-panel p-5 rounded-2xl border border-white/10 space-y-3">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <span>{country.flag}</span> {country.country}
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs text-slate-300">
              {country.resources.map((resource) => (
                <div key={resource.name} className="p-3 rounded-xl bg-white/5 space-y-0.5">
                  <strong className="text-white block font-semibold">{resource.name}</strong>
                  {resource.phone && (
                    <span className="block text-emerald-400 text-[11px] font-mono">
                      {resource.phoneLink ? (
                        <a href={resource.phoneLink} className="underline hover:text-emerald-300 transition-colors">{resource.phone}</a>
                      ) : (
                        resource.phone
                      )}
                    </span>
                  )}
                  <span className="block text-slate-400 text-[11px]">{resource.description}</span>
                </div>
              ))}
            </div>
          </section>
        ))}
      </div>

      <div className="mt-12 bg-white/5 rounded-2xl p-5 border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-xs">
        <div>
          <strong className="text-white block text-sm mb-0.5">Looking for SecretMsg Platform Assistance?</strong>
          <span className="text-slate-400">Our safety team is ready to assist with account concerns, block reports, or urgent guidance.</span>
        </div>
        <a href="mailto:safety@secretmsg.net" className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-full font-bold text-center shrink-0 transition-colors flex items-center gap-2">
          <Mail className="w-4 h-4" />
          Email Safety Team
        </a>
      </div>
    </PublicPage>
  );
};