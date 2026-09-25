export interface RouletteCategories {
  all: string[];
  crush: string[];
  spicy: string[];
  secrets: string[];
  chaotic: string[];
  realtalk: string[];
  latenight: string[];
}

export const ROULETTE_CATEGORY_KEYS = [
  'all',
  'crush',
  'spicy',
  'secrets',
  'chaotic',
  'realtalk',
  'latenight',
] as const;

export type RouletteCategory = (typeof ROULETTE_CATEGORY_KEYS)[number];

const loaders: Record<RouletteCategory, () => Promise<string[]>> = {
  all: () => import('@/data/roulette/all.json').then(module => module.default),
  crush: () => import('@/data/roulette/crush.json').then(module => module.default),
  spicy: () => import('@/data/roulette/spicy.json').then(module => module.default),
  secrets: () => import('@/data/roulette/secrets.json').then(module => module.default),
  chaotic: () => import('@/data/roulette/chaotic.json').then(module => module.default),
  realtalk: () => import('@/data/roulette/realtalk.json').then(module => module.default),
  latenight: () => import('@/data/roulette/latenight.json').then(module => module.default),
};

const cache = new Map<RouletteCategory, Promise<string[]>>();

export const loadRouletteCategory = (category: RouletteCategory): Promise<string[]> => {
  const cached = cache.get(category);
  if (cached) return cached;

  const loading = loaders[category]().then(prompts => {
    cache.set(category, Promise.resolve(prompts));
    return prompts;
  });
  cache.set(category, loading);
  return loading;
};
