export interface Env {
  ANTHROPIC_API_KEY: string;
  ENVIRONMENT: string;
  CACHE: KVNamespace;
  IMAGES: R2Bucket;
}
