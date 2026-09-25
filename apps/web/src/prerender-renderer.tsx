import type { ComponentType } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { MemoryRouter } from 'react-router-dom';
import { ApproachToSafetyPage } from '@/pages/ApproachToSafetyPage';
import { ChildSafetyPage } from '@/pages/ChildSafetyPage';
import { CommunityGuidelinesPage } from '@/pages/CommunityGuidelinesPage';
import { ContactPage } from '@/pages/ContactPage';
import { CookiesPage } from '@/pages/CookiesPage';
import { DisclaimerPage } from '@/pages/DisclaimerPage';
import { OnlineSafetyGuidePage } from '@/pages/OnlineSafetyGuidePage';
import { PrivacyPage } from '@/pages/PrivacyPage';
import { SafetyPage } from '@/pages/SafetyPage';
import { SafetyResourcesPage } from '@/pages/SafetyResourcesPage';
import { SafetyToolsPage } from '@/pages/SafetyToolsPage';
import { TermsPage } from '@/pages/TermsPage';

const pageComponents: Record<string, ComponentType> = {
  ApproachToSafetyPage,
  ChildSafetyPage,
  CommunityGuidelinesPage,
  ContactPage,
  CookiesPage,
  DisclaimerPage,
  OnlineSafetyGuidePage,
  PrivacyPage,
  SafetyPage,
  SafetyResourcesPage,
  SafetyToolsPage,
  TermsPage,
};

export const renderManifestPage = (routePath: string, componentName: string): string => {
  const Page = pageComponents[componentName];
  if (!Page) {
    throw new Error(`Cannot render route ${routePath}: component ${componentName} is not registered`);
  }

  let markup: string;
  try {
    markup = renderToStaticMarkup(
      <MemoryRouter initialEntries={[routePath]}>
        <Page />
      </MemoryRouter>,
    );
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    throw new Error(`Cannot render route ${routePath} with component ${componentName}: ${detail}`);
  }

  if (!markup) {
    throw new Error(`Cannot render route ${routePath} with component ${componentName}: empty markup`);
  }
  return markup;
};
