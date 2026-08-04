export class LegalParagraph {
  text: string;
  isHeading: boolean;

  constructor(text: string, isHeading: boolean = false) {
    this.text = text;
    this.isHeading = isHeading;
  }
}

/** Parses the heading/emphasis subset used by the bundled Demo legal resources. */
export function parseLegalDocument(body: string): LegalParagraph[] {
  let paragraphs: LegalParagraph[] = [];
  let parts: string[] = body.split('\n\n');
  for (let index: number = 0; index < parts.length; index++) {
    let value: string = parts[index].trim();
    if (value.length === 0) continue;
    let isHeading: boolean = value.startsWith('## ');
    let marked: string = isHeading ? value.substring(3) : value;
    paragraphs.push(new LegalParagraph(marked.replace(/\*\*/g, ''), isHeading));
  }
  return paragraphs;
}
