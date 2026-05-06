import { z, defineCollection } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date(),
    updatedDate: z.date().optional(),
    seoKeyword: z.string(),
    category: z.enum(['daily-planning', 'task-management', 'focus', 'comparison', 'adhd']),
    tags: z.array(z.string()),
  }),
});

export const collections = { blog };
