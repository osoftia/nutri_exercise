export interface PdfLine {
  text: string;
  bold?: boolean;
  size?: number;
  gap?: number;
}

export interface PdfPage {
  lines: PdfLine[];
}

const PAGE_WIDTH = 595.28;
const PAGE_HEIGHT = 841.89;
const MARGIN = 48;
const LINES_PER_PAGE = 46;

export function paginateLines(lines: readonly PdfLine[], linesPerPage = LINES_PER_PAGE): PdfPage[] {
  const pages: PdfPage[] = [];
  for (let index = 0; index < lines.length; index += linesPerPage) {
    pages.push({ lines: lines.slice(index, index + linesPerPage) });
  }
  return pages.length > 0 ? pages : [{ lines: [] }];
}

export function buildPdf(pages: readonly PdfPage[]): string {
  const objects = new Map<number, string>();
  const pageIds: number[] = [];
  let nextId = 5;

  for (const page of pages) {
    const pageId = nextId;
    const contentId = nextId + 1;
    nextId += 2;
    pageIds.push(pageId);
    objects.set(
      pageId,
      `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${PAGE_WIDTH} ${PAGE_HEIGHT}] ` +
        `/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents ${contentId} 0 R >>`,
    );
    const content = renderContent(page);
    objects.set(contentId, `<< /Length ${content.length} >>\nstream\n${content}\nendstream`);
  }

  objects.set(1, '<< /Type /Catalog /Pages 2 0 R >>');
  objects.set(
    2,
    `<< /Type /Pages /Kids [${pageIds.map((id) => `${id} 0 R`).join(' ')}] /Count ${pageIds.length} >>`,
  );
  objects.set(3, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
  objects.set(
    4,
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>',
  );

  const maxId = nextId - 1;
  let output = '%PDF-1.4\n';
  const offsets: number[] = new Array(maxId + 1).fill(0);
  for (let id = 1; id <= maxId; id += 1) {
    offsets[id] = output.length;
    output += `${id} 0 obj\n${objects.get(id) ?? ''}\nendobj\n`;
  }

  const xrefOffset = output.length;
  output += `xref\n0 ${maxId + 1}\n0000000000 65535 f \n`;
  for (let id = 1; id <= maxId; id += 1) {
    output += `${String(offsets[id]).padStart(10, '0')} 00000 n \n`;
  }
  output += `trailer\n<< /Size ${maxId + 1} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`;

  return output;
}

export function downloadPdf(filename: string, lines: readonly PdfLine[]): void {
  if (typeof URL === 'undefined' || typeof URL.createObjectURL !== 'function') {
    return;
  }
  const pdf = buildPdf(paginateLines(lines));
  const blob = new Blob([pdf], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  anchor.rel = 'noopener';
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function renderContent(page: PdfPage): string {
  const commands: string[] = [];
  let y = PAGE_HEIGHT - MARGIN;
  for (const line of page.lines) {
    const size = line.size ?? 11;
    const font = line.bold ? 'F2' : 'F1';
    y -= size;
    commands.push(
      `BT /${font} ${size} Tf 1 0 0 1 ${MARGIN} ${y.toFixed(2)} Tm (${escapeText(line.text)}) Tj ET`,
    );
    y -= line.gap ?? 4;
  }
  return commands.join('\n');
}

function escapeText(text: string): string {
  return ascii(text).replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

function ascii(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[\u2013\u2014]/g, '-')
    .replace(/[\u2018\u2019]/g, "'")
    .replace(/[\u201C\u201D]/g, '"')
    .replace(/[^\x20-\x7E]/g, ' ');
}
