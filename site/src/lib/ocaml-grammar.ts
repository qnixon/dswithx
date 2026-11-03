// A small TextMate grammar for OCaml. Shiki's bundled one tags comments with
// odd extra scopes, so the GitHub themes color them like code.
export const ocamlGrammar = {
  name: 'ocaml',
  scopeName: 'source.ocaml',
  patterns: [
    { include: '#comment' },
    { match: '"(?:[^"\\\\]|\\\\.)*"', name: 'string.quoted.double.ocaml' },
    { match: "'(?:[^'\\\\]|\\\\.)'", name: 'string.quoted.single.ocaml' },
    {
      match:
        '\\b(let|rec|in|and|if|then|else|match|with|function|fun|when|as|for|to|downto|do|done|while|begin|end|type|of|mutable|open|module|struct|sig|try|raise|exception|mod|land|lor|lxor|lsl|lsr|asr|not|or)\\b',
      name: 'keyword.control.ocaml',
    },
    { match: '\\b(true|false)\\b', name: 'constant.language.ocaml' },
    { match: '\\b[A-Z][A-Za-z0-9_\']*', name: 'entity.name.type.ocaml' },
    { match: '\\b\\d[\\d_]*(\\.[\\d_]*)?([eE][+-]?\\d+)?', name: 'constant.numeric.ocaml' },
  ],
  repository: {
    // OCaml comments nest: (* a (* b *) c *) is one comment.
    comment: {
      begin: '\\(\\*',
      end: '\\*\\)',
      name: 'comment.block.ocaml',
      patterns: [{ include: '#comment' }],
    },
  },
};
