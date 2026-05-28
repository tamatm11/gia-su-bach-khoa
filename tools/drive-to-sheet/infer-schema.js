// Stage 2: Suy ra schema hiển thị từ tree đã crawl bằng Claude Sonnet.
// Input: trees/<id>.json (output Stage 1)
// Output: schemas/<id>.json
//
// CLI:
//   node infer-schema.js --teacher <folderId>          # dùng cache nếu có
//   node infer-schema.js --teacher <folderId> --reinfer  # ép gọi lại AI
//
// Module API:
//   const { inferSchema, loadCachedSchema } = require('./infer-schema');

require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const fs = require('fs');
const path = require('path');
const Anthropic = require('@anthropic-ai/sdk');
const { loadCachedTree } = require('./crawl');

const SCHEMAS_DIR = path.join(__dirname, 'schemas');
const MODEL = process.env.INFER_MODEL || 'claude-sonnet-4-6';
const MAX_TREE_DEPTH = 6; // Đủ sâu để AI thấy pattern, không quá nhiều token

function ensureSchemasDir() {
  if (!fs.existsSync(SCHEMAS_DIR)) fs.mkdirSync(SCHEMAS_DIR, { recursive: true });
}

function schemaPath(teacherFolderId) {
  return path.join(SCHEMAS_DIR, `${teacherFolderId}.json`);
}

function loadCachedSchema(teacherFolderId) {
  const p = schemaPath(teacherFolderId);
  if (!fs.existsSync(p)) return null;
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch (_) {
    return null;
  }
}

function saveSchema(teacherFolderId, payload) {
  ensureSchemasDir();
  fs.writeFileSync(schemaPath(teacherFolderId), JSON.stringify(payload, null, 2));
}

// Rút gọn tree: chỉ giữ name + childCount + fileCount + (sample folder ids tới depth N).
// KHÔNG gửi file IDs/links/sizes → tiết kiệm token, AI cũng không cần.
function compactTree(tree, maxDepth = MAX_TREE_DEPTH) {
  function visit(node, depth) {
    const out = {
      id: node.id,
      name: node.name,
      folderCount: node.children.length,
      fileCount: node.files.length,
    };
    if (depth < maxDepth && node.children.length > 0) {
      out.children = node.children.map((c) => visit(c, depth + 1));
    } else if (node.children.length > 0) {
      out.children_truncated = node.children.length;
    }
    return out;
  }
  return {
    teacher: { id: tree.teacher.id, name: tree.teacher.name },
    courses: tree.courses.map((c) => visit(c, 0)),
  };
}

const SYSTEM_PROMPT = `Bạn là chuyên gia phân tích cấu trúc thư mục học liệu của giáo viên Việt Nam trên Google Drive.

Mỗi giáo viên có 1 folder gốc chứa các "khóa học" (cấp 0). Bên trong mỗi khóa có thể là Chương → Bài → Tiết, hoặc cấu trúc khác (vd LIVESTREAM, EZVOCAB, BÀI TẬP, ĐỀ THI THỬ...).

Nhiệm vụ của bạn: nhìn cây thư mục thực tế và đề xuất một schema hiển thị để khi render ra Google Sheet, học viên đọc dễ hiểu nhất.

OUTPUT: TRẢ VỀ DUY NHẤT 1 KHỐI JSON (không markdown, không giải thích), theo schema:

{
  "levels": [
    { "depth": 0, "label": "<nhãn cấp 0 viết hoa, ví dụ 'KHÓA HỌC' hoặc 'KHỐI BÀI'>", "icon": "<1 emoji>", "bold": true|false, "bg": "#RRGGBB" },
    ...
  ],
  "leafFolderHints": [
    { "namePattern": "<regex hoặc keyword nhận diện folder coi như 'bài học cuối'>", "reason": "<ngắn gọn>" }
  ],
  "notes": "<1-2 câu mô tả pattern cấu trúc bạn nhận ra ở giáo viên này>"
}

QUY TẮC:
- "depth" = 0 là cấp NGAY BÊN TRONG mỗi khóa (folder cấp 0 trong dữ liệu input).
- Phải có đúng số levels khớp với độ sâu thực tế tối đa của cây (xem dữ liệu).
- Icon emoji nên gợi đúng vai trò: 📚 cho khóa lớn, 📖 cho chương, 📂 cho bài, 📁 cho tiết, 🎥 cho livestream, 📝 cho đề/bài tập, 📘 cho lý thuyết, v.v.
- bg là mã hex pastel, level sâu thì nhạt dần. Mỗi level một sắc rõ ràng.
- bold=true ở các level "tiêu đề" (chương, bài), bold=false ở level "tiết" hoặc cấp thấp nhất.
- "leafFolderHints" giúp render dừng đệ quy sớm ở folder mà bạn nhận thấy là "đơn vị bài học cuối" (ví dụ folder bắt đầu bằng mã "TDMXX01_..."). Nếu không có pattern rõ → trả về [].
- "notes" mô tả ngắn nét đặc trưng (vd: "Khóa con bên trong mỗi khóa lớn được gắn mã 2 chữ cái 'TDMXX', mỗi mã là 1 chuyên đề; folder con bên trong mã là đơn vị bài giảng cuối.").

KHÔNG bịa cấp không tồn tại. KHÔNG xuất gì ngoài JSON.`;

async function inferSchema(teacherFolderId, { reinfer = false, model = MODEL } = {}) {
  if (!reinfer) {
    const cached = loadCachedSchema(teacherFolderId);
    if (cached) return { ...cached, fromCache: true };
  }

  const tree = loadCachedTree(teacherFolderId);
  if (!tree) {
    throw new Error(`Chưa có tree cho ${teacherFolderId}. Chạy: node crawl.js --teacher ${teacherFolderId}`);
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error('Thiếu ANTHROPIC_API_KEY trong .env');

  const clientOpts = {
    apiKey,
    defaultHeaders: {
      // Proxy bên thứ 3 (vd freemodel) thường gate theo User-Agent của Claude Code CLI.
      'User-Agent': process.env.ANTHROPIC_USER_AGENT || 'claude-cli/2.1.150 (external, cli)',
      'X-Stainless-Lang': 'js',
    },
  };
  if (process.env.ANTHROPIC_BASE_URL) clientOpts.baseURL = process.env.ANTHROPIC_BASE_URL;
  const client = new Anthropic(clientOpts);

  const compact = compactTree(tree);
  const userContent = `Dưới đây là cây thư mục thực tế của giáo viên "${compact.teacher.name}". Hãy phân tích và trả về schema theo đúng quy tắc system prompt.\n\n\`\`\`json\n${JSON.stringify(compact, null, 2)}\n\`\`\``;

  const resp = await client.messages.create({
    model,
    max_tokens: 2048,
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content: userContent }],
  });

  const text = resp.content
    .filter((b) => b.type === 'text')
    .map((b) => b.text)
    .join('\n')
    .trim();

  // Tách JSON khỏi markdown nếu có
  let jsonText = text;
  const fenced = /```(?:json)?\s*([\s\S]*?)```/.exec(text);
  if (fenced) jsonText = fenced[1].trim();

  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (e) {
    throw new Error(`AI trả về JSON không parse được:\n${text.slice(0, 500)}`);
  }

  const payload = {
    inferredAt: new Date().toISOString(),
    model,
    teacher: compact.teacher,
    usage: resp.usage,
    schema: parsed,
  };
  saveSchema(teacherFolderId, payload);
  return { ...payload, fromCache: false };
}

function parseArgs(argv) {
  const out = { reinfer: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--teacher' || a === '-t') out.teacherFolder = argv[++i];
    else if (a === '--reinfer') out.reinfer = true;
    else if (a === '--model') out.model = argv[++i];
  }
  return out;
}

async function main() {
  const args = parseArgs(process.argv);
  if (!args.teacherFolder) {
    console.error('Thiếu --teacher <folderId>');
    process.exit(1);
  }
  console.log(`Infer schema cho ${args.teacherFolder}${args.reinfer ? ' [reinfer]' : ''}`);
  const t0 = Date.now();
  const result = await inferSchema(args.teacherFolder, { reinfer: args.reinfer, model: args.model });
  const dt = ((Date.now() - t0) / 1000).toFixed(1);
  if (result.fromCache) {
    console.log(`Dùng cache schema (${dt}s)`);
  } else {
    console.log(`AI suy ra schema (${dt}s, ${result.usage?.input_tokens} in / ${result.usage?.output_tokens} out tokens)`);
  }
  console.log(JSON.stringify(result.schema, null, 2));
  console.log(`\nCache: ${schemaPath(args.teacherFolder)}`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error('LỖI:', e.message);
    process.exit(1);
  });
}

module.exports = { inferSchema, loadCachedSchema, schemaPath, SCHEMAS_DIR };
