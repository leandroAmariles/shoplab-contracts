/**
 * ShopLab Common Contracts - TypeScript / Angular Models
 */

export interface HealthStatus {
  status: 'UP' | 'DOWN' | 'DEGRADED';
  timestamp: string;
  serviceName?: string;
  version?: string;
}

export interface PingResponse {
  echo: string;
  serverTimeMillis: number;
}

export interface ErrorDto {
  code: string;
  description: string;
  attributes?: Record<string, string>;
}

export interface ErrorResponse {
  data?: unknown;
  errors: ErrorDto[];
}
