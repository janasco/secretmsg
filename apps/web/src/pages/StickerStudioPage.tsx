import React from 'react';
import { PublicPage } from '@/components/PublicPage';
import { StickerStudio } from '@/components/StickerStudio';

/**
 * Route shell only. The studio itself lives in `components/StickerStudio.tsx`
 * because it owns canvas state and is the single interactive element here.
 *
 * Nothing below this component touches `document` while rendering:
 * /sticker-studio is prerendered to static HTML, so canvas work is deferred
 * to an effect inside the studio.
 */
export const StickerStudioPage: React.FC = () => {
  return (
    <PublicPage
      title="Story Sticker Studio"
      eyebrow={`32 designs · one link`}
      description="Design a 9:16 story card for your anonymous message board. Pick a style, write your prompt or roll one at random, and export a full-resolution PNG."
      wide
    >
      <StickerStudio />
    </PublicPage>
  );
};
