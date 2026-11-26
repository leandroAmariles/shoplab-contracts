import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const npmDir = resolve(__dirname, '..');
const repoRoot = resolve(npmDir, '../..');
const srcDir = join(npmDir, 'src');

const specs = [
  { name: 'common', namespace: 'common', input: join(repoRoot, 'openapi/common/v1/common-api.yaml') },
  { name: 'chat', namespace: 'chat', input: join(repoRoot, 'openapi/chat/v1/chat-api.yaml') },
  { name: 'retrieval', namespace: 'retrieval', input: join(repoRoot, 'openapi/retrieval/v1/retrieval-api.yaml') },
  { name: 'eval', namespace: 'evalApi', input: join(repoRoot, 'openapi/eval/v1/eval-api.yaml') },
  { name: 'catalog', namespace: 'catalog', input: join(repoRoot, 'openapi/catalog/v1/catalog-api.yaml') },
];

rmSync(srcDir, { recursive: true, force: true });
mkdirSync(srcDir, { recursive: true });

const cliBin = join(
  npmDir,
  'node_modules/.bin',
  process.platform === 'win32' ? 'openapi-generator-cli.cmd' : 'openapi-generator-cli',
);

for (const spec of specs) {
  const outDir = join(srcDir, spec.name);
  const args = [
    'generate',
    '-i',
    spec.input,
    '-g',
    'typescript-angular',
    '-o',
    outDir,
    '--additional-properties=ngVersion=22.0.0,npmName=@leandroamariles/shoplab-contracts,supportsES6=true,useSingleRequestParameter=false',
  ];

  console.log(`Generating Angular TypeScript client for ${spec.name} from ${spec.input}...`);
  if (existsSync(cliBin)) {
    execFileSync(cliBin, args, { cwd: npmDir, stdio: 'inherit', shell: process.platform === 'win32' });
  } else {
    execFileSync('npx', ['openapi-generator-cli', ...args], {
      cwd: npmDir,
      stdio: 'inherit',
      shell: process.platform === 'win32',
    });
  }
}

const indexTs = `/**
 * @leandroamariles/shoplab-contracts
 * Auto-generated Angular TypeScript clients and OpenAPI models.
 */
export * as common from './common/index';
export * as chat from './chat/index';
export * as retrieval from './retrieval/index';
export * as evalApi from './eval/index';
export * as catalog from './catalog/index';

export type { ApiErrorResponse } from './common/model/apiErrorResponse';
export type { HealthStatus } from './common/model/healthStatus';
export type { PingResponse } from './common/model/pingResponse';
export type { ErrorDto } from './common/model/errorDto';
export type { ErrorResponse } from './common/model/errorResponse';

export type {
  AssistantSettingsResponse,
  ChatRequest,
  ChatSource,
  ChatSseDonePayload,
  ChatSseErrorPayload,
  ChatSseSourcesPayload,
  ChatSseStreamEvent,
  ChatSseTokenPayload,
  FeedbackItemResponse,
  FeedbackListResponse,
  FeedbackRating,
  FeedbackResponse,
  PromoteFeedbackRequest,
  PromptSourceType,
  ServedPromptResponse,
  SubmitFeedbackRequest,
} from './chat/model/models';
export {
  AssistantSettingsService,
  ChatService,
  FeedbackService,
} from './chat/api/api';

export type {
  DocumentStatus,
  DocumentSummaryResponse,
  DocumentUploadResponse,
  KnowledgeSearchHitResponse,
  KnowledgeSearchResponse,
} from './retrieval/model/models';
export {
  DocumentsService,
  KnowledgeSearchService,
} from './retrieval/api/api';

export type {
  CaseKind,
  CaseRequest,
  ComparedRunPart,
  ComparisonCasePart,
  ComparisonCountsPart,
  ComparisonMetricPart,
  ComparisonParameterPart,
  ComparisonStatus,
  EvalRunRequest,
  EvalRunSavedResponse,
  EvalSettingsPromptPart,
  EvalSettingsResponse,
  EvalSettingsRetrievalPart,
  EvaluatorRequest,
  JudgeRequest,
  MetricStatResponse,
  OriginCountResponse,
  PromptVersionRequest,
  ResultRequest,
  RetrievalConfigRequest,
  RunComparisonResponse,
  RunDetailEvaluatorPart,
  RunDetailHeaderResponse,
  RunDetailJudgePart,
  RunDetailResponse,
  RunDetailResultPart,
  RunDetailRetrievalPart,
  RunDetailScopePart,
  RunKind,
  RunListItemResponse,
  RunListResponse,
  RunPromptResponse,
  StoredRunResponse,
} from './eval/model/models';
export {
  EvalHistoryService,
  EvalRunsService,
  EvalSettingsService,
} from './eval/api/api';
`;

writeFileSync(join(srcDir, 'index.ts'), indexTs, 'utf8');
console.log('Generated barrel src/index.ts successfully.');
